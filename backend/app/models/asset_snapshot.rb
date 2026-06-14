class AssetSnapshot < ApplicationRecord
  belongs_to :asset_account

  validates :recorded_month, presence: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :asset_account_id, uniqueness: { scope: :recorded_month }
end
