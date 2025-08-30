class CategoryRule < ApplicationRecord
  belongs_to :category
  
  validates :keyword, presence: true, uniqueness: true
  validates :category_id, presence: true
  validates :priority, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  scope :by_priority, -> { order(priority: :desc, created_at: :desc) }
  
  # キーワードルール変更時にCSVファイルを更新
  after_create :update_csv_file
  after_update :update_csv_file
  after_destroy :update_csv_file
  
  def self.find_category_for_store(store_name)
    return nil if store_name.blank?
    
    # 店舗名を正規化（半角カタカナ→全角カタカナ、大小文字統一）
    normalized_store_name = normalize_text(store_name)
    
    # 優先度順でキーワードマッチング
    CategoryRule.by_priority.find_each do |rule|
      normalized_keyword = normalize_text(rule.keyword)
      
      if normalized_store_name.include?(normalized_keyword)
        return rule.category
      end
    end
    
    nil
  end
  
  private
  
  def update_csv_file
    # CSV更新を同期実行（少量のデータなので同期で十分）
    self.class.export_to_csv
  end
  
  def self.normalize_text(text)
    return '' if text.blank?
    
    # 半角カタカナを全角カタカナに変換し、大小文字を統一
    require 'nkf'
    normalized = NKF.nkf('-w -Z1', text).downcase
    
    # ハイフン、スペース、記号を統一（完全一致しやすくするため）
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
  
  def self.seed_default_rules
    default_rules = [
      # 優先度高（より具体的なキーワード）
      { keyword: 'Amazon', category: 'daily', priority: 10 },
      { keyword: 'アマゾン', category: 'daily', priority: 10 },
      { keyword: '楽天市場', category: 'daily', priority: 10 },
      { keyword: 'セブンイレブン', category: 'daily', priority: 9 },
      { keyword: 'ローソン', category: 'daily', priority: 9 },
      { keyword: 'ファミマ', category: 'daily', priority: 9 },
      { keyword: 'ファミリーマート', category: 'daily', priority: 9 },
      
      # 食費
      { keyword: 'イオン', category: 'food', priority: 8 },
      { keyword: 'スーパー', category: 'food', priority: 7 },
      { keyword: '業務スーパー', category: 'food', priority: 8 },
      { keyword: 'マクドナルド', category: 'food', priority: 8 },
      { keyword: 'マック', category: 'food', priority: 8 },
      { keyword: 'スタバ', category: 'entertainment', priority: 8 },
      { keyword: 'スターバックス', category: 'entertainment', priority: 8 },
      
      # 交通費
      { keyword: 'JR東日本', category: 'transport', priority: 9 },
      { keyword: '東京メトロ', category: 'transport', priority: 9 },
      { keyword: 'タクシー', category: 'transport', priority: 8 },
      
      # 住宅費
      { keyword: '電気', category: 'housing', priority: 8 },
      { keyword: 'ガス', category: 'housing', priority: 8 },
      { keyword: '水道', category: 'housing', priority: 8 },
      
      # より広いキーワード（優先度低）
      { keyword: 'コンビニ', category: 'daily', priority: 5 },
      { keyword: '通販', category: 'daily', priority: 5 }
    ]
    
    default_rules.each do |rule|
      category = Category.find_by(name: rule[:category]) || 
                Category.find_by(name: rule[:category].capitalize) ||
                Category.find_by(name: case rule[:category]
                  when 'daily' then '日用品費'
                  when 'food' then '食費'
                  when 'entertainment' then '娯楽費'
                  when 'transport' then '交通費'  
                  when 'housing' then '住宅費'
                  when 'investment' then '投資'
                  else 'その他'
                end)
      
      if category
        CategoryRule.find_or_create_by(
          keyword: rule[:keyword]
        ) do |cr|
          cr.category = category
          cr.priority = rule[:priority]
        end
      end
    end
  end
end