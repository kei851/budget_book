namespace :categories do
  desc "Fix マイバスケット transactions to be classified as food instead of transport"
  task fix_maibasket: :environment do
    puts "マイバスケットの取引を食費カテゴリに修正中..."
    
    # 食費カテゴリを取得
    food_category = Category.find_by(name: '食費')
    unless food_category
      puts "食費カテゴリが見つかりません"
      exit 1
    end
    
    # マイバスケットの取引を検索
    maibasket_transactions = Transaction.where("store_name LIKE ?", "%マイバスケット%")
    
    puts "見つかった取引数: #{maibasket_transactions.count}"
    
    # カテゴリを食費に更新
    updated_count = maibasket_transactions.update_all(category_id: food_category.id)
    
    puts "更新完了: #{updated_count}件の取引を食費カテゴリに変更しました"
  end
  
  desc "Reclassify all transactions based on current keyword rules"
  task reclassify_all: :environment do
    puts "全取引のカテゴリを現在のルールで再分類中..."
    
    classifier = CategoryClassifierService.new
    updated_count = 0
    
    Transaction.find_each do |transaction|
      new_category = classifier.classify(transaction.store_name)
      if new_category && transaction.category_id != new_category.id
        transaction.update!(category: new_category)
        updated_count += 1
        puts "#{transaction.store_name} -> #{new_category.name}"
      end
    end
    
    puts "再分類完了: #{updated_count}件の取引を更新しました"
  end
end