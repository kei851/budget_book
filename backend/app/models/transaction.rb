class Transaction < ApplicationRecord
  belongs_to :category, optional: true  # 未分類の取引も許可
  belongs_to :upload_history, optional: true
  
  validates :transaction_date, presence: true
  validates :store_name, presence: true, length: { maximum: 500 }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  
  scope :recent, -> { order(transaction_date: :desc) }
  scope :by_date_range, ->(start_date, end_date) { where(transaction_date: start_date..end_date) }
  scope :by_category, ->(category_id) { where(category_id: category_id) }
  scope :by_amount_range, ->(min_amount, max_amount) { where(amount: min_amount..max_amount) }
  
  # 月次集計用スコープ
  scope :monthly_summary, -> {
    group("strftime('%Y-%m', transaction_date)")
    .group(:category_id)
    .sum(:amount)
  }
  
  # 楽天カードCSVの生データを解析してTransactionを作成
  def self.create_from_csv_row(csv_row, category = nil)
    new(
      transaction_date: Date.parse(csv_row[0]),  # "利用日"
      store_name: csv_row[1],                    # "利用店名・商品名"  
      user_name: csv_row[2],                     # "利用者"
      payment_method: csv_row[3],                # "支払方法"
      amount: csv_row[4].to_f,                   # "利用金額"
      raw_data: csv_row.to_s,                    # 生データ保存
      category: category,
      auto_classified: category.present?
    )
  end
  
  def formatted_amount
    "¥#{amount.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse}"
  end
end
