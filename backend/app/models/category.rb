class Category < ApplicationRecord
  has_many :transactions, dependent: :nullify
  has_many :category_keywords, dependent: :destroy
  
  validates :name, presence: true, uniqueness: true
  validates :color, presence: true, format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: "must be a valid hex color code" }
  validates :display_order, presence: true, numericality: { only_integer: true }
  
  scope :ordered, -> { order(:display_order, :name) }
  
  def transaction_count
    transactions.count
  end
  
  def total_amount
    transactions.sum(:amount)
  end
  
  def keywords_list
    category_keywords.ordered_by_priority.pluck(:keyword)
  end
end
