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

# 既存キーワードをDBに移行
keywords_data = {
  '食費' => [
    'マイバスケット', # 高優先度：特定の店舗名を最初に
    'セブンイレブン', 'ローソン', 'ファミマ', 'ファミリーマート', 'デイリーヤマザキ',
    'マクドナルド', 'ケンタッキー', 'スターバックス', 'ドトール', 'タリーズ',
    'すき家', '松屋', '吉野家', '大戸屋', 'サイゼリヤ', 'ガスト', 'ジョナサン',
    'イオン', '西友', 'ライフ', '成城石井', '業務スーパー', 'コストコ',
    'amazon', 'rakuten', '楽天', 'uber', 'ubereats', '出前館',
    'スーパー', 'コンビニ', 'レストラン', '居酒屋', 'カフェ', '喫茶',
    '食堂', 'グルメ', '弁当', 'パン', 'ケーキ', 'pizza',
    'セブン-イレブン', 'マツヤ', 'ホットモット', 'ジャパンミート'
  ],
  '交通費' => [
    'jr', 'JR', '駅', '電車', '地下鉄', 'メトロ', '私鉄', 'バス',
    'タクシー', 'uber', '新幹線', '航空', 'ana', 'jal', 'peach',
    'ガソリン', 'エネオス', 'シェル', 'コスモ', 'エッソ', 'モービル',
    '駐車場', 'パーキング', '高速道路', 'etc', 'nexco',
    '交通', '運賃', '乗車券', '定期券', '回数券', 'バス', 'PASMO'
  ],
  '娯楽費' => [
    'netflix', 'amazon prime', 'spotify', 'apple music', 'youtube',
    'steam', 'playstation', 'nintendo', 'xbox',
    '映画', 'シネマ', '劇場', 'コンサート', 'ライブ', 'カラオケ',
    '遊園地', 'ディズニー', 'usj', '水族館', '動物園', '博物館',
    'パチンコ', 'パチスロ', '競馬', '競輪', '宝くじ',
    '娯楽', 'エンタメ', 'ゲーム', 'アプリ'
  ],
  '日用品費' => [
    'ドラッグストア', 'マツキヨ', 'ウエルシア', 'サンドラッグ', 'ツルハ',
    'ダイソー', 'セリア', 'キャンドゥ', '100円ショップ',
    'ニトリ', 'ikea', 'イケア', '無印良品', 'loft', 'ロフト', '東急ハンズ',
    'ホームセンター', 'コーナン', 'カインズ', 'コメリ',
    '薬局', '化粧品', '洗剤', 'シャンプー', 'トイレットペーパー',
    '日用品', '雑貨', '生活用品', '消耗品'
  ]
}

puts "\nキーワードデータを投入中..."

keywords_data.each do |category_name, keywords|
  category = Category.find_by(name: category_name)
  next unless category
  
  puts "カテゴリ: #{category_name}"
  keywords.each_with_index do |keyword, index|
    # 優先順位は重要なキーワードを高く設定
    priority = keywords.length - index
    
    keyword_record = CategoryKeyword.find_or_create_by!(
      category: category,
      keyword: keyword.downcase
    ) do |k|
      k.priority = priority
    end
    
    print "  ✓ #{keyword}"
  end
  puts "\n"
end

puts "\n#{CategoryKeyword.count} 個のキーワードが作成されました。"