# トランザクションテーブルにアップロード履歴IDを追加するマイグレーション
# どのCSVファイルからインポートされたデータかを追跡可能にする
class AddUploadHistoryIdToTransactions < ActiveRecord::Migration[8.0]
  def change
    # upload_history_id カラムと外部キー制約を追加
    # null: true（既存データとの互換性のため必須ではない）
    add_reference :transactions, :upload_history, null: true, foreign_key: true
  end
end
