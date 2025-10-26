# カテゴリキーワードテーブル作成マイグレーション
# 店舗名からカテゴリを自動判定するためのキーワード管理
class CreateCategoryKeywords < ActiveRecord::Migration[8.0]
  def change
    create_table :category_keywords do |t|
      t.references :category, null: false, foreign_key: true  # 分類先のカテゴリ
      t.string :keyword, null: false                          # 判定用キーワード（例：「スーパー」→食費）
      t.integer :priority, default: 0                         # 優先度（大きいほど優先）

      t.timestamps
    end

    # 同じカテゴリに同じキーワードの重複登録を防止
    add_index :category_keywords, [:category_id, :keyword], unique: true
    # キーワードでの検索を高速化（自動分類処理で使用）
    add_index :category_keywords, :keyword
  end
end
