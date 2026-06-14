class CreateAssetAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :asset_accounts do |t|
      t.string :name
      t.string :account_type
      t.integer :display_order

      t.timestamps
    end
  end
end
