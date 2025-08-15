class Api::V1::TransactionsController < ApplicationController
  before_action :set_transaction, only: [:update]

  def index
    @transactions = Transaction.includes(:category).order(transaction_date: :desc)
    
    # 月次フィルタ
    if params[:month].present?
      start_date = Date.parse("#{params[:month]}-01")
      end_date = start_date.end_of_month
      @transactions = @transactions.where(transaction_date: start_date..end_date)
    end
    
    # カテゴリフィルタ
    if params[:category_id].present?
      @transactions = @transactions.where(category_id: params[:category_id])
    end
    
    # ページネーション
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
      # 既存の取引データを削除
      Transaction.delete_all if params[:clear_existing] == 'true'
      
      # CSVインポート実行
      import_service = CsvImportService.new(params[:csv_file])
      result = import_service.import
      
      if result[:success]
        render json: {
          message: 'CSVインポートが完了しました',
          imported_count: result[:imported_count],
          total_rows: result[:total_rows],
          errors: result[:errors]
        }
      else
        render json: {
          error: 'CSVインポートに失敗しました',
          errors: result[:errors]
        }, status: :unprocessable_entity
      end
    rescue => e
      Rails.logger.error "Import Error: #{e.message}"
      render json: { error: "インポート処理中にエラーが発生しました: #{e.message}" }, status: :internal_server_error
    end
  end

  def monthly
    # 月次集計データを取得
    transactions = Transaction.includes(:category)
    
    # 指定月または全期間
    if params[:year] && params[:month]
      start_date = Date.new(params[:year].to_i, params[:month].to_i, 1)
      end_date = start_date.end_of_month
      transactions = transactions.where(transaction_date: start_date..end_date)
    end
    
    # カテゴリ別集計
    category_totals = transactions.joins(:category)
                                .group('categories.name', 'categories.color')
                                .sum(:amount)
    
    # 月別推移データ
    monthly_totals = transactions.group_by_month(:transaction_date)
                               .sum(:amount)
    
    render json: {
      category_totals: category_totals.map { |k, v| { category: k[0], color: k[1], total: v } },
      monthly_totals: monthly_totals,
      total_amount: transactions.sum(:amount),
      transaction_count: transactions.count
    }
  end

  def analytics
    # 分析用データを取得
    transactions = Transaction.includes(:category)
    
    # 期間指定
    if params[:start_date] && params[:end_date]
      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date])
      transactions = transactions.where(transaction_date: start_date..end_date)
    else
      # デフォルトは全期間
      # transactions = transactions (期間制限なし)
    end
    
    # カテゴリ別分析
    category_stats = transactions.joins(:category)
                               .group('categories.name', 'categories.color')
                               .group_by_month(:transaction_date)
                               .sum(:amount)
    
    # 日別集計
    daily_totals = transactions.group_by_day(:transaction_date)
                             .sum(:amount)
    
    # トップ支出店舗
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
      grouped[category] ||= { name: category, color: color, monthly_data: {} }
      grouped[category][:monthly_data][date] = value
    end
    grouped.values
  end
end
