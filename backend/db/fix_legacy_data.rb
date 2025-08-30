# 既存データを一時的な履歴に関連付けるスクリプト
legacy_history = UploadHistory.create!(
  filename: "legacy_data.csv",
  upload_date: Time.current,
  imported_count: Transaction.where(upload_history_id: nil).count,
  description: "既存データ（履歴管理前）"
)

Transaction.where(upload_history_id: nil).update_all(upload_history_id: legacy_history.id)

puts "既存データを履歴ID #{legacy_history.id} に関連付けました"
puts "対象件数: #{Transaction.where(upload_history_id: legacy_history.id).count}"