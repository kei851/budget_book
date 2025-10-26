# カテゴリテーブル作成マイグレーション
# 支出・収入のカテゴリ管理用（例：食費、交通費、給与など）
class CreateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :categories do |t|
      t.string :name, null: false         # カテゴリ名（例：食費、交通費）
      t.string :color, null: false        # HEX色コード（例：#FF5733）
      t.string :icon                      # アイコン名（オプション）
      t.text :description                 # カテゴリの説明（オプション）
      t.integer :display_order, default: 0 # 表示順序（小さいほど上位）

      t.timestamps
    end

    # カテゴリ名の一意性制約（重複防止）
    add_index :categories, :name, unique: true
    # 表示順序での検索を高速化
    add_index :categories, :display_order
  end
end
