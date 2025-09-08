# 楽天カードCSVファイルの解析・インポートサービス

class CsvImportService
  # csv, nkfを使用する。csvとはCSVファイルを解析するためのgem、nkfとは文字コードを変換するためのgem
  require 'csv'
  require 'nkf'
  
  # initializeメソッドはcsv_fileとupload_historyを受け取り、4つの関数を初期化する
  def initialize(csv_file, upload_history = nil)
    @csv_file = csv_file
    @upload_history = upload_history
    @imported_count = 0
    @errors = []
  end
  
  #importメソッドはCSVファイルを解析し、データベースに保存する
  def import
    begin
      # CSVファイルの内容を読み取り
      content = @csv_file.read
      
      # 強制的にバイナリとして読み取り、エンコーディングを処理
      content = content.force_encoding('BINARY')
      
      # BOM（UTF-8などの文字コードを示すためのマーク）を検出して除去
      if content.start_with?("\xEF\xBB\xBF".force_encoding('BINARY'))
        content = content[3..-1] # BOMを除去
        content = content.force_encoding('UTF-8')
      elsif content.start_with?("\xFF\xFE".force_encoding('BINARY'))
        # UTF-16LE BOM（UTF-16LEとは、UTF-16の小端形式のバイトオーダー）
        content = content[2..-1]
        content = content.force_encoding('UTF-16LE').encode('UTF-8')
      elsif content.start_with?("\xFE\xFF".force_encoding('BINARY'))
        # UTF-16BE BOM（UTF-16BEとは、UTF-16のビッグエンディアン形式のバイトオーダー）
        content = content[2..-1]
        content = content.force_encoding('UTF-16BE').encode('UTF-8')
      else
        # BOMがない場合、エンコーディングを推測
        begin
          # まずUTF-8として試行（UTF-8として無効な場合、Shift_JISとして変換）
          content = content.force_encoding('UTF-8')
          unless content.valid_encoding?
            # UTF-8として無効な場合、Shift_JISとして変換
            content = content.force_encoding('Shift_JIS').encode('UTF-8')
          end
        rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
          # Shift_JISでも変換できない場合、NKFを使用
          content = NKF.nkf('-w -S', content.force_encoding('BINARY'))
        end
      end
      
      # 改行コードを統一し、余分な空行を除去
      content = content.gsub(/\r\n/, "\n").gsub(/\r/, "\n")
      content = content.strip
      
      # CSVパース設定（楽天カード用）- より柔軟な設定
      csv_options = {
        headers: true,
        encoding: 'UTF-8',
        liberal_parsing: true,
        quote_char: '"',
        col_sep: ',',
        skip_blanks: true
      }
      #CSV.parseはCSVファイルを解析するためのメソッド
      csv_data = CSV.parse(content, **csv_options)
      
      # データが空の場合の処理
      if csv_data.empty?
        return {
          success: true,  # 空ファイルは成功として扱う
          imported_count: 0,
          total_rows: 0,
          errors: ["CSVファイルは空でした"]
        }
      end
      
      # デバッグ情報をログに出力
      Rails.logger.info "CSV Headers: #{csv_data.headers.inspect}"
      Rails.logger.info "CSV First Row: #{csv_data.first.to_h.inspect}" if csv_data.first
      
      #csv_data.each_with_indexはCSVファイルを解析するためのメソッド
      csv_data.each_with_index do |row, index|
        next if row.to_h.values.all?(&:blank?) # 空行をスキップ
        import_transaction(row, index + 2) # ヘッダー行があるので+2
      end
      
      {
        success: @errors.empty? || @imported_count > 0,  # インポートが1件でもあれば成功
        imported_count: @imported_count,
        total_rows: csv_data.size,
        errors: @errors
      }
    #rescueはエラーが発生した場合の処理
    rescue => e
      #Rails.logger.errorはエラーをログに出力する
      Rails.logger.error "CSV Import Error: #{e.message}"
      {
        success: false,
        imported_count: 0,
        total_rows: 0,
        errors: ["CSVファイルの読み込みに失敗しました: #{e.message}"]
      }
    end
  end
  
  private

  #import_transactionメソッドはCSVファイルを解析し、データベースに保存する
  def import_transaction(row, row_number)
    # 楽天カードCSVの具体的な構造に基づいて処理
    # "利用日","利用店名・商品名","利用者","支払方法","利用金額","支払手数料","支払総額","7月支払金額","8月繰越残高","新規サイン"
    
    transaction_date = parse_date(row['利用日'])
    store_name = row['利用店名・商品名']&.strip
    amount = parse_amount(row['利用金額'])
    user_name = row['利用者']&.strip
    payment_method = row['支払方法']&.strip
    
    # デバッグ情報
    Rails.logger.info "Row #{row_number}: date=#{transaction_date}, store=#{store_name}, amount=#{amount}"
    
    #transaction_date、store_name、amountがnilの場合、エラーを返す
    if transaction_date.nil? || store_name.blank? || amount.nil?
      missing_fields = []
      missing_fields << "日付" if transaction_date.nil?
      missing_fields << "店舗名" if store_name.blank?
      missing_fields << "金額" if amount.nil?
      return add_error(row_number, "必須項目が不足しています: #{missing_fields.join(', ')}")
    end
    
    # カテゴリ自動分類（CategoryRule.find_category_for_storeメソッドを使用）
    category = classify_category(store_name)
    
    #Transaction.newはTransactionクラスのインスタンスを作成する
    transaction = Transaction.new(
      transaction_date: transaction_date,
      store_name: store_name,
      user_name: user_name,
      payment_method: payment_method,
      amount: amount,
      category: category,
      auto_classified: category.present?,
      raw_data: row.to_h.to_json,
      upload_history: @upload_history
    )
    
    #transaction.saveはtransactionを保存する
    if transaction.save
      #@imported_countはインポートした件数をカウントする
      @imported_count += 1
    else
      #add_errorメソッドはエラーを追加する
      add_error(row_number, "データ保存エラー: #{transaction.errors.full_messages.join(', ')}")
    end
  #rescueはエラーが発生した場合の処理
  rescue => e
    #add_errorメソッドはエラーを追加する
    add_error(row_number, "処理エラー: #{e.message}")
  end
  
  #parse_dateメソッドは日付を解析する
  def parse_date(date_str)
    #date_strが空の場合、nilを返す
    return nil if date_str.blank?
    
    #date_strを文字列に変換してスペースを除去
    date_str = date_str.to_s.strip
    
    # 日付形式のパターンを試行
    date_patterns = [
      '%Y/%m/%d',    # 2024/08/15
      '%Y-%m-%d',    # 2024-08-15
      '%m/%d/%Y',    # 08/15/2024
      '%d/%m/%Y',    # 15/08/2024
      '%Y年%m月%d日'  # 2024年08月15日
    ]
    
    #date_patterns.eachはdate_patternsの要素を順番に取り出してpatternに代入し、eachメソッドを実行する
    date_patterns.each do |pattern|
      begin
        #Date.strptimeは日付を解析する
        return Date.strptime(date_str, pattern)
      #rescueはエラーが発生した場合の処理
      rescue ArgumentError
        next
      end
    end
    
    # パターンマッチに失敗した場合はDate.parseを試行
    Date.parse(date_str)
  rescue => e
    #Rails.logger.warnはエラーをログに出力する
    Rails.logger.warn "Date parsing error: #{date_str} -> #{e.message}"
    nil
  end
  
  #parse_amountメソッドは金額を解析する
  def parse_amount(amount_str)
    #amount_strが空の場合、nilを返す
    return nil if amount_str.blank?
    
    # 文字列に変換
    amount_str = amount_str.to_s.strip
    
    # 金額の前処理（カンマ、円マーク、全角文字を除去）
    clean_amount = amount_str.gsub(/[,，￥¥円\s]/, '')
    
    # マイナス記号の処理
    is_negative = clean_amount.include?('-') || clean_amount.include?('−')
    clean_amount = clean_amount.gsub(/[-−]/, '')
    
    # 数値のみを抽出
    clean_amount = clean_amount.gsub(/[^0-9.]/, '')
    
    #clean_amountが空の場合、nilを返す
    return nil if clean_amount.blank?
    
    # 浮動小数点に変換
    result = clean_amount.to_f
    result = -result if is_negative
    
    # 0の場合はnilを返す（無効なデータとして扱う）
    result == 0.0 ? nil : result
  rescue => e
    Rails.logger.warn "Amount parsing error: #{amount_str} -> #{e.message}"
    nil
  end
  
  #classify_categoryメソッドはカテゴリを分類する
  def classify_category(store_name)
    # キーワードルールベースの分類を優先
    category = CategoryRule.find_category_for_store(store_name)
    return category if category
    
    # フォールバック: 従来のサービスを使用
    CategoryClassifierService.new.classify(store_name)
  end
  
  #add_errorメソッドはエラーを追加する
  def add_error(row_number, message)
    @errors << "#{row_number}行目: #{message}"
  end
end