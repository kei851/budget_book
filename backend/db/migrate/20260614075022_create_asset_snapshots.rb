class CreateAssetSnapshots < ActiveRecord::Migration[8.0]
  def change
    create_table :asset_snapshots do |t|
      t.references :asset_account, null: false, foreign_key: true
      t.integer :amount, null: false, default: 0
      t.date :recorded_month, null: false

      t.timestamps
    end
    add_index :asset_snapshots, [:asset_account_id, :recorded_month], unique: true
  end
end
