# トランザクション（取引）テーブル作成マイグレーション
# CSVからインポートされた支出・収入データを保存
class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.references :category, foreign_key: true  # カテゴリへの参照（null許可：未分類もあり得る）
      t.date :transaction_date, null: false      # 取引日
      t.string :store_name, null: false, limit: 500  # 店舗名・取引先名
      t.decimal :amount, null: false, precision: 12, scale: 2  # 金額（精度12桁、小数点2桁）
      t.string :payment_method, limit: 100       # 支払い方法（例：現金、クレジット）
      t.string :user_name, limit: 100            # 利用者名
      t.string :payment_month, limit: 50         # 支払月（クレジット決済などで使用）
      t.text :raw_data                           # 元のCSVデータ（デバッグ・検証用）
      t.boolean :auto_classified, default: true  # 自動分類フラグ（true: 自動、false: 手動）

      t.timestamps
    end

    # 日付での検索を高速化（年月別集計などで使用）
    add_index :transactions, :transaction_date
    # 金額での検索・集計を高速化
    add_index :transactions, :amount
    # category_id インデックスは t.references で自動作成される
    # 日付と金額の複合検索を高速化（期間別金額集計で使用）
    add_index :transactions, [:transaction_date, :amount]
  end
end
