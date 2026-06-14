class AiCategoryClassifierService
  CATEGORIES = {
    "投資" => 1,
    "食費" => 2,
    "日用品費" => 3,
    "娯楽費" => 4,
    "住宅費" => 5,
    "交通費" => 6,
    "その他" => 7
  }.freeze

  BATCH_SIZE = 30

  def classify_batch(store_names)
    return {} if store_names.blank?

    client = Anthropic::Client.new(api_key: ENV.fetch("ANTHROPIC_API_KEY"))
    results = {}

    store_names.each_slice(BATCH_SIZE) do |batch|
      prompt = build_prompt(batch)
      response = client.messages.create(
        model: "claude-opus-4-5",
        max_tokens: 1024,
        messages: [{ role: "user", content: prompt }]
      )
      parse_response(response.content.first.text, batch, results)
    rescue => e
      Rails.logger.error "AI分類エラー: #{e.message}"
    end

    results
  end

  private

  def build_prompt(store_names)
    store_list = store_names.each_with_index.map { |name, i| "#{i}: #{name}" }.join("\n")

    <<~PROMPT
      以下の店舗名・サービス名を、家計簿のカテゴリに分類してください。

      カテゴリ定義:
      1: 投資（証券、投資信託、仮想通貨など）
      2: 食費（スーパー、コンビニ、飲食店、デリバリーなど）
      3: 日用品費（ドラッグストア、ホームセンター、雑貨店など）
      4: 娯楽費（映画、ゲーム、音楽、サブスクリプションなど）
      5: 住宅費（家賃、電気、ガス、水道、通信費など）
      6: 交通費（電車、バス、タクシー、ガソリン、駐車場など）
      7: その他（上記に当てはまらないもの）

      分類する店舗名:
      #{store_list}

      必ず以下のJSON形式のみで回答してください。説明は不要です:
      [{"index": 0, "category_id": 2}, {"index": 1, "category_id": 6}, ...]
    PROMPT
  end

  def parse_response(text, batch, results)
    json_match = text.match(/\[.*\]/m)
    return unless json_match

    parsed = JSON.parse(json_match[0])
    parsed.each do |item|
      index = item["index"].to_i
      category_id = item["category_id"].to_i
      next unless (0...batch.size).cover?(index) && CATEGORIES.value?(category_id)

      results[batch[index]] = category_id
    end
  rescue JSON::ParserError => e
    Rails.logger.error "AI分類JSONパースエラー: #{e.message}"
  end
end
