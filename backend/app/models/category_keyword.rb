class CategoryKeyword < ApplicationRecord
  belongs_to :category
  
  validates :keyword, presence: true, 
                     uniqueness: { scope: :category_id, message: "このカテゴリにはすでに同じキーワードが登録されています" }
  validates :priority, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  scope :ordered_by_priority, -> { order(priority: :desc, keyword: :asc) }
  scope :for_classification, -> { ordered_by_priority }
  
  before_save :normalize_keyword
  
  private
  
  def normalize_keyword
    self.keyword = keyword.strip.downcase if keyword.present?
  end
end