#upload_historyクラスはApplicationRecordクラスを継承している。つまり、データベースと連携する
class UploadHistory < ApplicationRecord
  #upload_historyは複数のtransactionに紐づき、upload_historyが削除された時にそのtransactionも削除される
  has_many :transactions, dependent: :destroy
  
  #upload_historyはfilenameが必須
  validates :filename, presence: true
  #upload_historyはupload_dateが必須
  validates :upload_date, presence: true
  #upload_historyはimported_countが必須で、0以上の整数
  validates :imported_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  #upload_historyはupload_dateで降順で並び替える
  scope :recent, -> { order(upload_date: :desc) }
  
  #display_nameメソッドはfilenameとimported_countを表示する
  def display_name
    "#{filename} (#{imported_count}件)"
  end
  
  #formatted_upload_dateメソッドはupload_dateをAsia/Tokyoの時間に変換して表示する
  def formatted_upload_date
    upload_date.in_time_zone("Asia/Tokyo").strftime("%Y/%m/%d %H:%M JST")
  end
  
  #privateメソッド
  private
  
  #generate_file_hashメソッドはfile_contentのMD5ハッシュを生成する
  def generate_file_hash(file_content)
    Digest::MD5.hexdigest(file_content)
  end
end