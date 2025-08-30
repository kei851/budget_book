# 楽天カードCSVファイルの解析・インポートサービス
class CsvImportService
  require 'csv'
  require 'nkf'
  
  def initialize(csv_file, upload_history = nil)
    @csv_file = csv_file
    @upload_history = upload_history
    @imported_count = 0
    @errors = []
  end
  
  def import
    begin
      # CSVファイルの内容を読み取り
      content = @csv_file.read
      
      # 強制的にバイナリとして読み取り、エンコーディングを処理
      content = content.force_encoding('BINARY')
      
      # BOMを検出して除去
      if content.start_with?("\xEF\xBB\xBF".force_encoding('BINARY'))
        content = content[3..-1] # BOMを除去
        content = content.force_encoding('UTF-8')
      elsif content.start_with?("\xFF\xFE".force_encoding('BINARY'))
        # UTF-16LE BOM
        content = content[2..-1]
        content = content.force_encoding('UTF-16LE').encode('UTF-8')
      elsif content.start_with?("\xFE\xFF".force_encoding('BINARY'))
        # UTF-16BE BOM
        content = content[2..-1]
        content = content.force_encoding('UTF-16BE').encode('UTF-8')
      else
        # BOMがない場合、エンコーディングを推測
        begin
          # まずUTF-8として試行
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
    rescue => e
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
    
    if transaction_date.nil? || store_name.blank? || amount.nil?
      missing_fields = []
      missing_fields << "日付" if transaction_date.nil?
      missing_fields << "店舗名" if store_name.blank?
      missing_fields << "金額" if amount.nil?
      return add_error(row_number, "必須項目が不足しています: #{missing_fields.join(', ')}")
    end
    
    # カテゴリ自動分類
    category = classify_category(store_name)
    
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
    
    if transaction.save
      @imported_count += 1
    else
      add_error(row_number, "データ保存エラー: #{transaction.errors.full_messages.join(', ')}")
    end
  rescue => e
    add_error(row_number, "処理エラー: #{e.message}")
  end
  
  def parse_date(date_str)
    return nil if date_str.blank?
    
    date_str = date_str.to_s.strip
    
    # 日付形式のパターンを試行
    date_patterns = [
      '%Y/%m/%d',    # 2024/08/15
      '%Y-%m-%d',    # 2024-08-15
      '%m/%d/%Y',    # 08/15/2024
      '%d/%m/%Y',    # 15/08/2024
      '%Y年%m月%d日'  # 2024年08月15日
    ]
    
    date_patterns.each do |pattern|
      begin
        return Date.strptime(date_str, pattern)
      rescue ArgumentError
        next
      end
    end
    
    # パターンマッチに失敗した場合はDate.parseを試行
    Date.parse(date_str)
  rescue => e
    Rails.logger.warn "Date parsing error: #{date_str} -> #{e.message}"
    nil
  end
  
  def parse_amount(amount_str)
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
  
  def classify_category(store_name)
    # キーワードルールベースの分類を優先
    category = CategoryRule.find_category_for_store(store_name)
    return category if category
    
    # フォールバック: 従来のサービスを使用
    CategoryClassifierService.new.classify(store_name)
  end
  
  def add_error(row_number, message)
    @errors << "#{row_number}行目: #{message}"
  end
end