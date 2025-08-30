class AddUploadHistoryIdToTransactions < ActiveRecord::Migration[8.0]
  def change
    add_reference :transactions, :upload_history, null: true, foreign_key: true
  end
end
