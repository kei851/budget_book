require 'csv'
require 'nkf'

class CsvImportService
  def initialize(csv_file, upload_history = nil)
    @csv_file = csv_file
    @upload_history = upload_history
    @imported_count = 0
    @errors = []
    @data_source_type = 'rakuten'
  end

  def import
    content = @csv_file.read.force_encoding('BINARY')

    content = if content.start_with?("\xEF\xBB\xBF".force_encoding('BINARY'))
      content[3..].force_encoding('UTF-8')
    elsif content.start_with?("\xFF\xFE".force_encoding('BINARY'))
      content[2..].force_encoding('UTF-16LE').encode('UTF-8')
    elsif content.start_with?("\xFE\xFF".force_encoding('BINARY'))
      content[2..].force_encoding('UTF-16BE').encode('UTF-8')
    else
      begin
        utf8 = content.force_encoding('UTF-8')
        utf8.valid_encoding? ? utf8 : content.force_encoding('Shift_JIS').encode('UTF-8')
      rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
        NKF.nkf('-w -S', content.force_encoding('BINARY'))
      end
    end

    # 半角カタカナ→全角カタカナ変換でキーワードマッチング精度を向上
    content = NKF.nkf('-w -Z1', content)
    content = content.gsub(/\r\n/, "\n").gsub(/\r/, "\n").strip

    lines = content.split("\n")
    first_line = lines[0] || ""
    second_line = lines[1] || ""

    if first_line.include?('ご利用年月日') || second_line.include?('ご利用年月日')
      @data_source_type = 'epos'
      lines.shift
      content = lines.join("\n")
    elsif first_line.include?('利用日')
      @data_source_type = 'rakuten'
    end

    csv_data = CSV.parse(content, headers: true, encoding: 'UTF-8', liberal_parsing: true, quote_char: '"', col_sep: ',', skip_blanks: true)

    @data_source_type = detect_data_source(csv_data.headers)
    @upload_history&.update!(data_source_type: @data_source_type)

    if csv_data.empty?
      return { success: true, imported_count: 0, total_rows: 0, errors: ["CSVファイルは空でした"] }
    end

    Rails.logger.info "CSV Headers: #{csv_data.headers.inspect}"
    Rails.logger.info "CSV First Row: #{csv_data.first.to_h.inspect}" if csv_data.first

    csv_data.each_with_index do |row, index|
      next if row.to_h.values.all?(&:blank?)
      import_transaction(row, index + 2)
    end

    {
      success: @errors.empty? || @imported_count > 0,
      imported_count: @imported_count,
      total_rows: csv_data.size,
      errors: @errors
    }
  rescue => e
    Rails.logger.error "CSV Import Error: #{e.message}"
    { success: false, imported_count: 0, total_rows: 0, errors: ["CSVファイルの読み込みに失敗しました: #{e.message}"] }
  end

  private

  def detect_data_source(headers)
    if headers.include?('ご利用年月日')
      'epos'
    elsif headers.include?('利用日')
      'rakuten'
    else
      'rakuten'
    end
  end

  def get_column_name(column_type)
    case column_type
    when :date   then @data_source_type == 'epos' ? 'ご利用年月日' : '利用日'
    when :store  then @data_source_type == 'epos' ? 'ご利用場所' : '利用店名・商品名'
    when :amount then @data_source_type == 'epos' ? 'ご利用金額(キャッシングでは元金になります)' : '利用金額'
    when :user   then @data_source_type == 'epos' ? nil : '利用者'
    when :payment_method then @data_source_type == 'epos' ? '支払区分' : '支払方法'
    end
  end

  def import_transaction(row, row_number)
    transaction_date = parse_date(row[get_column_name(:date)])
    store_name = row[get_column_name(:store)]&.strip
    amount = parse_amount(row[get_column_name(:amount)])
    user_name = row[get_column_name(:user)]&.strip
    payment_method = row[get_column_name(:payment_method)]&.strip

    Rails.logger.info "Row #{row_number}: date=#{transaction_date}, store=#{store_name}, amount=#{amount}"

    if transaction_date.nil? || store_name.blank? || amount.nil?
      missing_fields = []
      missing_fields << "日付" if transaction_date.nil?
      missing_fields << "店舗名" if store_name.blank?
      missing_fields << "金額" if amount.nil?
      return add_error(row_number, "必須項目が不足しています: #{missing_fields.join(', ')}")
    end

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
    date_patterns = ['%Y/%m/%d', '%Y-%m-%d', '%m/%d/%Y', '%d/%m/%Y', '%Y年%m月%d日']

    date_patterns.each do |pattern|
      return Date.strptime(date_str, pattern)
    rescue ArgumentError
      next
    end

    Date.parse(date_str)
  rescue => e
    Rails.logger.warn "Date parsing error: #{date_str} -> #{e.message}"
    nil
  end

  def parse_amount(amount_str)
    return nil if amount_str.blank?

    amount_str = amount_str.to_s.strip
    clean_amount = amount_str.gsub(/[,，￥¥円\s]/, '')

    is_negative = clean_amount.include?('-') || clean_amount.include?('−')
    clean_amount = clean_amount.gsub(/[-−]/, '').gsub(/[^0-9.]/, '')

    return nil if clean_amount.blank?

    result = clean_amount.to_f
    result = -result if is_negative
    result == 0.0 ? nil : result
  rescue => e
    Rails.logger.warn "Amount parsing error: #{amount_str} -> #{e.message}"
    nil
  end

  def classify_category(store_name)
    CategoryRule.find_category_for_store(store_name) || CategoryClassifierService.new.classify(store_name)
  end

  def add_error(row_number, message)
    @errors << "#{row_number}行目: #{message}"
  end
end
