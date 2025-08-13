# 家計簿アプリの初期データ投入
# 機能仕様書で定義されたカテゴリを作成

categories_data = [
  { name: '投資', color: '#FF6384', display_order: 1, description: '証券、保険、銀行手数料' },
  { name: '食費', color: '#4BC0C0', display_order: 2, description: 'スーパー、コンビニ、レストラン、カフェ' },
  { name: '日用品費', color: '#9966FF', display_order: 3, description: '日用品、雑貨、消耗品' },
  { name: '娯楽費', color: '#36A2EB', display_order: 4, description: '映画、ゲーム、スポーツ施設' },
  { name: '住宅費', color: '#FF9F40', display_order: 5, description: '家賃、管理費、修繕費' },
  { name: '交通費', color: '#FFCE56', display_order: 6, description: 'JR、私鉄、バス、タクシー、ガソリン' },
  { name: 'その他', color: '#C9CBCF', display_order: 99, description: '上記に該当しないもの' }
]

puts "カテゴリデータを投入中..."

categories_data.each do |category_attrs|
  category = Category.find_or_create_by!(name: category_attrs[:name]) do |c|
    c.color = category_attrs[:color]
    c.display_order = category_attrs[:display_order]
    c.description = category_attrs[:description]
  end
  
  puts "✓ #{category.name} (#{category.color})"
end

puts "\n#{Category.count} 個のカテゴリが作成されました。"