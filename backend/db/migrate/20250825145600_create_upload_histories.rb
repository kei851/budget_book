# アップロード履歴テーブル作成マイグレーション
# CSVファイルのアップロード履歴を管理（重複インポート防止）
class CreateUploadHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :upload_histories do |t|
      t.string :filename, null: false        # アップロードされたファイル名
      t.datetime :upload_date, null: false   # アップロード日時
      t.integer :imported_count, default: 0  # インポート件数
      t.string :file_hash                    # ファイルのハッシュ値（重複チェック用）
      t.text :description                    # 備考・説明

      t.timestamps
    end

    # アップロード日時での検索を高速化
    add_index :upload_histories, :upload_date
    # ファイルハッシュでの重複チェックを高速化
    add_index :upload_histories, :file_hash
  end
end
