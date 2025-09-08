# カテゴリ自動分類サービス
class CategoryClassifierService
  #classifyメソッドはstore_nameを受け取り、store_nameに合致するカテゴリを返す
  def classify(store_name)
    #store_nameが空の場合、nilを返す
    return nil if store_name.blank?
    
    # 半角カタカナを全角カタカナに変換
    #store_name_normalizedに半角カタカナを全角カタカナに変換したものを代入
    store_name_normalized = NKF.nkf('-w', store_name)

    #store_name_lowerにstore_name_normalizedを小文字に変換したものを代入
    store_name_lower = store_name_normalized.downcase
    
    # 優先順位の高い順にキーワードをチェック
    # キーワードごとに検索してマッチした場合、そのカテゴリを返す
    matching_keywords = CategoryKeyword.joins(:category)
                                     .for_classification
                                     .select('category_keywords.*, categories.name as category_name')
    
    #matching_keywordsごとにループを回す。
    matching_keywords.each do |keyword_record|
      #store_name_lowerにkeyword_record.keyword.downcaseが含まれていたら、keyword_record.categoryを返す（優先度が高いcategoryを採用する）
      if store_name_lower.include?(keyword_record.keyword.downcase)
        return keyword_record.category
      end
    end
    
    nil
  end
end