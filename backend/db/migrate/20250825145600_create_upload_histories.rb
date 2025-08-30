class CreateUploadHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :upload_histories do |t|
      t.string :filename, null: false
      t.datetime :upload_date, null: false
      t.integer :imported_count, default: 0
      t.string :file_hash
      t.text :description

      t.timestamps
    end
    
    add_index :upload_histories, :upload_date
    add_index :upload_histories, :file_hash
  end
end
