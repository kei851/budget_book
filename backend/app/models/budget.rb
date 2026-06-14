class Budget < ApplicationRecord
  belongs_to :category

  validates :year, :month, :amount, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :category_id, uniqueness: { scope: [:year, :month] }

  scope :for_month, ->(year, month) { where(year: year, month: month) }
end
