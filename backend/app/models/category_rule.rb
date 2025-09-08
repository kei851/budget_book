#category_ruleクラスはApplicationRecordクラスを継承している。つまり、データベースと連携する
class CategoryRule < ApplicationRecord
  #一つのcategory_ruleは1つのcategoryに紐づく
  belongs_to :category
  
  #category_ruleはkeywordが必須で、重複を許さない
  validates :keyword, presence: true, uniqueness: true

  #category_ruleはcategory_idが必須
  validates :category_id, presence: true

  #category_ruleはpriorityが必須で、0以上の整数
  validates :priority, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  #category_ruleはpriorityで降順、created_atで降順で並び替える
  scope :by_priority, -> { order(priority: :desc, created_at: :desc) }
  
  # キーワードルール変更時にCSVファイルを更新（update_csv_fileメソッドを実行）
  after_create :update_csv_file
  after_update :update_csv_file
  after_destroy :update_csv_file
  
  #find_category_for_storeメソッドはstore_nameを受け取り、store_nameに合致するカテゴリを返す
  def self.find_category_for_store(store_name)
    #store_nameが空の場合、nilを返す
    return nil if store_name.blank?
    
    # 店舗名を正規化（半角カタカナ→全角カタカナ、大小文字統一）
    normalized_store_name = normalize_text(store_name)
    
    # 優先度順でキーワードマッチング
    CategoryRule.by_priority.find_each do |rule|
      #rule.keywordを正規化（半角カタカナ→全角カタカナ、大小文字統一）
      normalized_keyword = normalize_text(rule.keyword)
      
      #normalized_store_nameにnormalized_keywordが含まれていたら、rule.categoryを返す
      if normalized_store_name.include?(normalized_keyword)
        return rule.category
      end
    end
    
    nil
  end
  
  private
  
  #update_csv_fileメソッドはCSVファイルを更新する
  def update_csv_file
    # CSV更新を同期実行（少量のデータなので同期で十分）
    self.class.export_to_csv
  end
  
  #normalize_textメソッドはtextを正規化する
  def self.normalize_text(text)
    #textが空の場合、空文字列を返す
    return '' if text.blank?
    
    # 半角カタカナを全角カタカナに変換し、大小文字を統一
    require 'nkf'

    normalized = NKF.nkf('-w -Z1', text).downcase
    
    # ハイフン、スペース、記号を統一（完全一致しやすくするため）
    normalized.gsub(/[-−‐ー_\s　]/, '')
  end
  
  #export_to_csvメソッドはCSVファイルを更新する
  def self.export_to_csv
    #CSVファイルのパスを取得
    csv_file_path = Rails.root.join('..', 'data', 'category_for_classification.csv')
    
    require 'csv'
    
    #CSVファイルを作成
    CSV.open(csv_file_path, 'w', encoding: 'UTF-8') do |csv|
      #CSVファイルのヘッダーを作成
      csv << ['店舗名', 'カテゴリ']
      
      #CategoryRule.includes(:category).by_priority.each do |rule|
      CategoryRule.includes(:category).by_priority.each do |rule|
        #rule.keyword, rule.category.nameをCSVファイルに書き込む
        csv << [rule.keyword, rule.category.name]
      end
    end
    
    #CSVファイルを更新したことをログに出力
    Rails.logger.info "CSVファイルを更新しました: #{csv_file_path}"
  rescue => e # ← eに例外オブジェクトが入る
    Rails.logger.error "CSV更新エラー: #{e.message}"
  end
end