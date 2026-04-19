class CategoryRule < ApplicationRecord
  belongs_to :category

  validates :keyword, presence: true, uniqueness: true
  validates :category_id, presence: true
  validates :priority, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :by_priority, -> { order(priority: :desc, created_at: :desc) }

  after_create :update_csv_file
  after_update :update_csv_file
  after_destroy :update_csv_file

  def self.find_category_for_store(store_name)
    return nil if store_name.blank?

    normalized_store_name = normalize_text(store_name)

    CategoryRule.by_priority.find_each do |rule|
      normalized_keyword = normalize_text(rule.keyword)
      return rule.category if normalized_store_name.include?(normalized_keyword)
    end

    nil
  end

  private

  def update_csv_file
    self.class.export_to_csv
  end

  def self.normalize_text(text)
    return '' if text.blank?

    require 'nkf'
    normalized = NKF.nkf('-w -Z1', text).downcase
    normalized.gsub(/[-−‐ー_\s　]/, '')
  end

  def self.export_to_csv
    csv_file_path = Rails.root.join('..', 'data', 'category_for_classification.csv')

    require 'csv'
    CSV.open(csv_file_path, 'w', encoding: 'UTF-8') do |csv|
      csv << ['店舗名', 'カテゴリ']
      CategoryRule.includes(:category).by_priority.each do |rule|
        csv << [rule.keyword, rule.category.name]
      end
    end

    Rails.logger.info "CSVファイルを更新しました: #{csv_file_path}"
  rescue => e
    Rails.logger.error "CSV更新エラー: #{e.message}"
  end
end
