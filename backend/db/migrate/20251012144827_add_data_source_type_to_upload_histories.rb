class AddDataSourceTypeToUploadHistories < ActiveRecord::Migration[8.0]
  def change
    add_column :upload_histories, :data_source_type, :string, default: 'rakuten', null: false
  end
end
