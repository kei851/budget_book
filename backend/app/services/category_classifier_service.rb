# カテゴリ自動分類サービス
class CategoryClassifierService
  def classify(store_name)
    return nil if store_name.blank?
    
    # 半角カタカナを全角カタカナに変換
    store_name_normalized = NKF.nkf('-w', store_name)
    store_name_lower = store_name_normalized.downcase
    
    # 優先順位の高い順にキーワードをチェック
    # キーワードごとに検索してマッチした場合、そのカテゴリを返す
    matching_keywords = CategoryKeyword.joins(:category)
                                     .for_classification
                                     .select('category_keywords.*, categories.name as category_name')
    
    matching_keywords.each do |keyword_record|
      if store_name_lower.include?(keyword_record.keyword.downcase)
        return keyword_record.category
      end
    end
    
    nil
  end
end