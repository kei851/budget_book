class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.references :category, foreign_key: true # null許可（未分類もある）
      t.date :transaction_date, null: false
      t.string :store_name, null: false, limit: 500
      t.decimal :amount, null: false, precision: 12, scale: 2
      t.string :payment_method, limit: 100
      t.string :user_name, limit: 100  
      t.string :payment_month, limit: 50
      t.text :raw_data # 元のCSVデータ
      t.boolean :auto_classified, default: true

      t.timestamps
    end
    
    add_index :transactions, :transaction_date
    add_index :transactions, :amount
    # category_id インデックスは t.references で自動作成される
    add_index :transactions, [:transaction_date, :amount]
  end
end
