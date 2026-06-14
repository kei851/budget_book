class Api::V1::UploadHistoriesController < ApplicationController
  before_action :set_upload_history, only: [:show, :destroy]

  # GET /api/v1/upload_histories
  def index
    @upload_histories = UploadHistory.recent.includes(:transactions)
    
    histories_data = @upload_histories.map do |history|
      txns = history.transactions
      date_min = txns.minimum(:transaction_date)
      date_max = txns.maximum(:transaction_date)
      {
        id: history.id,
        filename: history.filename,
        upload_date: history.formatted_upload_date,
        imported_count: history.imported_count,
        transaction_count: txns.count,
        display_name: history.display_name,
        data_source_type: history.data_source_type,
        date_from: date_min&.strftime('%Y/%m/%d'),
        date_to:   date_max&.strftime('%Y/%m/%d'),
        date_range_label: date_min && date_max ? "#{date_min.strftime('%Y年%m月')}〜#{date_max.strftime('%Y年%m月')}" : nil
      }
    end

    # 全体のカバレッジ
    all_min = Transaction.minimum(:transaction_date)
    all_max = Transaction.maximum(:transaction_date)
    total_transactions = Transaction.count

    render json: {
      upload_histories: histories_data,
      total_count: @upload_histories.count,
      coverage: {
        date_from: all_min&.strftime('%Y/%m/%d'),
        date_to:   all_max&.strftime('%Y/%m/%d'),
        label: all_min && all_max ? "#{all_min.strftime('%Y年%m月')}〜#{all_max.strftime('%Y年%m月')}" : nil,
        total_transactions: total_transactions
      }
    }
  end

  # GET /api/v1/upload_histories/:id
  def show
    render json: {
      id: @upload_history.id,
      filename: @upload_history.filename,
      upload_date: @upload_history.formatted_upload_date,
      imported_count: @upload_history.imported_count,
      transaction_count: @upload_history.transactions.count,
      transactions: @upload_history.transactions.includes(:category).map do |transaction|
        {
          id: transaction.id,
          transaction_date: transaction.transaction_date.strftime('%Y-%m-%d'),
          store_name: transaction.store_name,
          amount: transaction.amount,
          category: transaction.category&.name
        }
      end
    }
  end

  # DELETE /api/v1/upload_histories/:id
  def destroy
    transaction_count = @upload_history.transactions.count
    filename = @upload_history.filename
    
    # 関連するトランザクションも一緒に削除
    @upload_history.destroy
    
    render json: {
      message: "#{filename}のデータ（#{transaction_count}件）を削除しました",
      deleted_transaction_count: transaction_count
    }
  rescue => e
    Rails.logger.error "Upload History Delete Error: #{e.message}"
    render json: { error: "削除処理でエラーが発生しました: #{e.message}" }, status: :internal_server_error
  end

  private

  def set_upload_history
    @upload_history = UploadHistory.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'アップロード履歴が見つかりません' }, status: :not_found
  end
end