class Api::V1::TransactionsController < ApplicationController
  before_action :set_transaction, only: [:update]

  def index
    @transactions = Transaction.includes(:category).order(transaction_date: :desc)

    if params[:month].present?
      start_date = Date.parse("#{params[:month]}-01")
      @transactions = @transactions.where(transaction_date: start_date..start_date.end_of_month)
    end

    if params[:category_id].present?
      @transactions = @transactions.where(category_id: params[:category_id])
    end

    page = params[:page] || 1
    per_page = params[:per_page] || 50
    @transactions = @transactions.page(page).per(per_page)

    render json: {
      transactions: @transactions.as_json(include: :category),
      total_count: @transactions.total_count,
      current_page: @transactions.current_page,
      total_pages: @transactions.total_pages
    }
  end

  def update
    if @transaction.update(transaction_params)
      render json: @transaction.as_json(include: :category)
    else
      render json: { errors: @transaction.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def import
    unless params[:csv_file].present?
      render json: { error: 'CSVファイルが選択されていません' }, status: :bad_request
      return
    end

    begin
      Rails.logger.info "CSV Import Started: #{params[:csv_file].original_filename}"

      file_hash = Digest::MD5.hexdigest(params[:csv_file].read)
      params[:csv_file].rewind

      existing_upload = UploadHistory.find_by(file_hash: file_hash)
      if existing_upload
        render json: {
          error: 'このファイルは既にアップロード済みです',
          existing_upload: {
            filename: existing_upload.filename,
            upload_date: existing_upload.upload_date,
            imported_count: existing_upload.imported_count
          }
        }, status: :unprocessable_entity
        return
      end

      Transaction.delete_all if params[:clear_existing] == 'true'

      upload_history = UploadHistory.create!(
        filename: params[:csv_file].original_filename,
        upload_date: Time.current,
        file_hash: file_hash
      )

      params[:csv_file].rewind

      result = CsvImportService.new(params[:csv_file], upload_history).import

      Rails.logger.info "CSV Import Result: #{result.inspect}"

      if result[:success] || result[:imported_count] > 0
        upload_history.update!(imported_count: result[:imported_count])
        render json: {
          message: 'CSVインポートが完了しました',
          imported_count: result[:imported_count],
          total_rows: result[:total_rows],
          errors: result[:errors],
          upload_history_id: upload_history.id
        }
      else
        Rails.logger.error "CSV Import Failed: #{result[:errors]}"
        render json: { error: 'CSVインポートに失敗しました', errors: result[:errors] }, status: :unprocessable_entity
      end
    rescue => e
      Rails.logger.error "Import Error: #{e.message}\n#{e.backtrace.join("\n")}"
      render json: { error: "インポート処理中にエラーが発生しました: #{e.message}" }, status: :internal_server_error
    end
  end

  def monthly
    transactions = Transaction.includes(:category)

    if params[:year] && params[:month]
      start_date = Date.new(params[:year].to_i, params[:month].to_i, 1)
      transactions = transactions.where(transaction_date: start_date..start_date.end_of_month)
    end

    category_totals = transactions.joins(:category)
                                  .group('categories.name', 'categories.color')
                                  .sum(:amount)

    monthly_totals = transactions.group_by_month(:transaction_date).sum(:amount)

    render json: {
      category_totals: category_totals.map { |k, v| { category: k[0], color: k[1], total: v } },
      monthly_totals: monthly_totals,
      total_amount: transactions.sum(:amount),
      transaction_count: transactions.count
    }
  end

  def analytics
    transactions = Transaction.includes(:category)

    if params[:start_date] && params[:end_date]
      transactions = transactions.where(
        transaction_date: Date.parse(params[:start_date])..Date.parse(params[:end_date])
      )
    end

    category_stats = transactions.joins(:category)
                                 .group('categories.name', 'categories.color')
                                 .group_by_month(:transaction_date)
                                 .sum(:amount)

    daily_totals = transactions.group_by_day(:transaction_date).sum(:amount)

    top_stores = transactions.group(:store_name)
                             .sum(:amount)
                             .sort_by { |_, total| -total }
                             .first(10)

    render json: {
      category_stats: format_category_stats(category_stats),
      daily_totals: daily_totals,
      top_stores: top_stores.map { |store, total| { store: store, total: total } },
      total_amount: transactions.sum(:amount),
      average_daily: transactions.sum(:amount) / [transactions.group_by_day(:transaction_date).count.size, 1].max
    }
  end

  private

  def set_transaction
    @transaction = Transaction.find(params[:id])
  end

  def transaction_params
    params.require(:transaction).permit(:category_id, :store_name, :amount, :transaction_date)
  end

  def format_category_stats(stats)
    grouped = {}
    stats.each do |key, value|
      category, color, date = key
      grouped[category] ||= { name: category, color: color, monthly_data: {}, total: 0, count: 0 }
      grouped[category][:monthly_data][date] = value || 0
      grouped[category][:total] += (value || 0)
    end

    category_counts = Transaction.joins(:category).group('categories.name').count
    grouped.each do |category_name, data|
      data[:count] = category_counts[category_name] || 0
      data[:id] = Category.find_by(name: category_name)&.id
    end

    # Chart.jsの積み上げ順序（配列の最初が上になる）
    display_order = ['その他', '投資', '住宅費', '交通費', '日用品費', '食費', '娯楽費']
    grouped.values.sort_by { |cat| display_order.index(cat[:name]) || 999 }
  rescue StandardError => e
    Rails.logger.error "Format category stats error: #{e.message}"
    []
  end
end
