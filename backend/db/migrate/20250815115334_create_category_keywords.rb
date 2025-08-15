class CreateCategoryKeywords < ActiveRecord::Migration[8.0]
  def change
    create_table :category_keywords do |t|
      t.references :category, null: false, foreign_key: true
      t.string :keyword, null: false
      t.integer :priority, default: 0

      t.timestamps
    end
    
    add_index :category_keywords, [:category_id, :keyword], unique: true
    add_index :category_keywords, :keyword
  end
end
