class Transaction < ApplicationRecord
  belongs_to :category, optional: true
  belongs_to :upload_history, optional: true

  validates :transaction_date, presence: true
  validates :store_name, presence: true, length: { maximum: 500 }
  validates :amount, presence: true, numericality: { greater_than: 0 }

  scope :recent, -> { order(transaction_date: :desc) }
  scope :by_date_range, ->(start_date, end_date) { where(transaction_date: start_date..end_date) }
  scope :by_category, ->(category_id) { where(category_id: category_id) }
  scope :by_amount_range, ->(min_amount, max_amount) { where(amount: min_amount..max_amount) }

  scope :monthly_summary, -> {
    group("strftime('%Y-%m', transaction_date)")
    .group(:category_id)
    .sum(:amount)
  }

  def self.create_from_csv_row(csv_row, category = nil)
    new(
      transaction_date: Date.parse(csv_row[0]),
      store_name: csv_row[1],
      user_name: csv_row[2],
      payment_method: csv_row[3],
      amount: csv_row[4].to_f,
      raw_data: csv_row.to_s,
      category: category,
      auto_classified: category.present?
    )
  end

  def formatted_amount
    "¥#{amount.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse}"
  end
end
