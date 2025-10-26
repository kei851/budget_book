# カテゴリルールテーブル作成マイグレーション
# 店舗名マッチングによる自動カテゴリ分類ルールを管理
class CreateCategoryRules < ActiveRecord::Migration[8.0]
  def change
    create_table :category_rules do |t|
      t.string :keyword, null: false      # マッチング用キーワード（店舗名の一部）
      t.integer :category_id, null: false # 分類先カテゴリID
      t.integer :priority, default: 0     # 優先度（複数マッチ時に高い方を採用）

      t.timestamps
    end

    # キーワードでの検索を高速化（自動分類時のルール検索で使用）
    add_index :category_rules, :keyword
    # カテゴリIDでの検索を高速化
    add_index :category_rules, :category_id
    # 優先度での並び替えを高速化
    add_index :category_rules, :priority
    # カテゴリテーブルへの外部キー制約
    add_foreign_key :category_rules, :categories
  end
end
