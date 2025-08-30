class CreateCategoryRules < ActiveRecord::Migration[8.0]
  def change
    create_table :category_rules do |t|
      t.string :keyword, null: false
      t.integer :category_id, null: false
      t.integer :priority, default: 0

      t.timestamps
    end
    
    add_index :category_rules, :keyword
    add_index :category_rules, :category_id
    add_index :category_rules, :priority
    add_foreign_key :category_rules, :categories
  end
end
