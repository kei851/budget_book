class UploadHistory < ApplicationRecord
  has_many :transactions, dependent: :destroy
  
  validates :filename, presence: true
  validates :upload_date, presence: true
  validates :imported_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  scope :recent, -> { order(upload_date: :desc) }
  
  def display_name
    "#{filename} (#{imported_count}件)"
  end
  
  def formatted_upload_date
    upload_date.in_time_zone("Asia/Tokyo").strftime("%Y/%m/%d %H:%M JST")
  end
  
  private
  
  def generate_file_hash(file_content)
    Digest::MD5.hexdigest(file_content)
  end
end