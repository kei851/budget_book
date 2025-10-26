require 'csv'

namespace :db do
  desc "Import category rules from CSV file"
  task import_category_rules: :environment do
    csv_file_path = Rails.root.join('..', 'data', 'category_for_classification.csv')
    
    unless File.exist?(csv_file_path)
      puts "CSVファイルが見つかりません: #{csv_file_path}"
      exit 1
    end
    
    # 既存のキーワードルールを削除
    puts "既存のキーワードルールを削除中..."
    CategoryKeyword.delete_all
    
    # カテゴリの名前とIDのマッピングを作成
    category_mapping = Category.all.map { |c| [c.name, c.id] }.to_h
    puts "カテゴリマッピング: #{category_mapping}"
    
    # CSVファイルを読み込み
    imported_count = 0
    errors = []
    
    CSV.foreach(csv_file_path, headers: true, encoding: 'UTF-8') do |row|
      store_name = row['店舗名']&.strip
      category_name = row['カテゴリ']&.strip
      
      next if store_name.blank? || category_name.blank?
      
      # カテゴリIDを取得
      category_id = category_mapping[category_name]
      
      if category_id.nil?
        errors << "カテゴリが見つかりません: #{category_name} (店舗: #{store_name})"
        next
      end
      
      # 優先度を設定（店舗名の長さに基づいて設定）
      priority = case store_name.length
      when 1..3
        5  # 短い名前は低優先度
      when 4..6
        8  # 中程度の名前
      else
        10 # 長い名前は高優先度
      end
      
      # キーワードを全角に正規化
      require 'nkf'
      normalized_keyword = NKF.nkf('-w -Z1', store_name) # 半角カタカナを全角カタカナに変換
      
      # キーワードルールを作成
      begin
        CategoryKeyword.create!(
          keyword: normalized_keyword,
          category_id: category_id,
          priority: priority
        )
        imported_count += 1
      rescue => e
        errors << "ルール作成エラー: #{store_name} -> #{normalized_keyword} - #{e.message}"
      end
    end
    
    puts "インポート完了:"
    puts "  成功: #{imported_count}件"
    puts "  エラー: #{errors.count}件"
    
    if errors.any?
      puts "\nエラー詳細:"
      errors.each { |error| puts "  - #{error}" }
    end
    
    puts "\n現在のキーワードルール件数: #{CategoryKeyword.count}"
  end
end