class CreateBudgets < ActiveRecord::Migration[8.0]
  def change
    create_table :budgets do |t|
      t.integer :category_id, null: false
      t.integer :year, null: false
      t.integer :month, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false

      t.timestamps
    end
    add_index :budgets, [:category_id, :year, :month], unique: true
  end
end
