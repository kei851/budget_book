class AssetAccount < ApplicationRecord
  has_many :asset_snapshots, dependent: :destroy

  ACCOUNTS = [
    { name: '楽天銀行',   account_type: 'bank',       display_order: 1 },
    { name: 'ゆうちょ銀行', account_type: 'bank',       display_order: 2 },
    { name: '楽天証券',   account_type: 'investment',  display_order: 3 },
    { name: '現金',      account_type: 'cash',        display_order: 4 },
    { name: 'PayPay',   account_type: 'emoney',      display_order: 5 },
    { name: 'Pasmo',    account_type: 'emoney',      display_order: 6 }
  ].freeze

  def self.seed!
    ACCOUNTS.each do |attrs|
      find_or_create_by!(name: attrs[:name]) do |a|
        a.account_type = attrs[:account_type]
        a.display_order = attrs[:display_order]
      end
    end
  end
end
