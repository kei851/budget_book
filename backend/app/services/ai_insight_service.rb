class AiInsightService
  def monthly_summary(year, month)
    data = build_monthly_data(year, month)
    return nil if data[:total_amount] == 0

    client = Anthropic::Client.new(api_key: ENV.fetch("ANTHROPIC_API_KEY"))
    response = client.messages.create(
      model: "claude-opus-4-5",
      max_tokens: 1024,
      system_: "あなたは家計管理のアドバイザーです。データに基づいて日本語で簡潔かつ具体的に分析してください。箇条書きや見出しを使わず、自然な文章で200〜300字程度でまとめてください。",
      messages: [{ role: "user", content: summary_prompt(data, year, month) }]
    )
    response.content.first.text
  rescue => e
    Rails.logger.error "AIサマリエラー: #{e.message}"
    nil
  end

  def home_insights(months_data)
    return nil if months_data.blank?

    client = Anthropic::Client.new(api_key: ENV.fetch("ANTHROPIC_API_KEY"))
    response = client.messages.create(
      model: "claude-opus-4-5",
      max_tokens: 768,
      system_: "あなたは家計管理のアドバイザーです。日本語で簡潔にトレンドを分析してください。150字程度でまとめてください。",
      messages: [{ role: "user", content: insights_prompt(months_data) }]
    )
    response.content.first.text
  rescue => e
    Rails.logger.error "AIインサイトエラー: #{e.message}"
    nil
  end

  def build_context_for_chat
    now = Time.current
    monthly = build_monthly_data(now.year, now.month)
    {
      current_month: "#{now.year}年#{now.month}月",
      total_amount: monthly[:total_amount],
      category_breakdown: monthly[:category_totals],
      transaction_count: monthly[:transaction_count]
    }
  end

  private

  def build_monthly_data(year, month)
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month

    txns = Transaction.where(transaction_date: start_date..end_date)
    total = txns.sum(:amount).round
    count = txns.count

    category_totals = txns
      .joins("LEFT JOIN categories ON categories.id = transactions.category_id")
      .group("categories.name")
      .sum(:amount)
      .map { |name, amount| { category: name || "未分類", amount: amount.round } }
      .sort_by { |h| -h[:amount] }

    {
      year: year,
      month: month,
      total_amount: total,
      transaction_count: count,
      category_totals: category_totals
    }
  end

  def summary_prompt(data, year, month)
    categories_text = data[:category_totals].map { |c|
      "#{c[:category]}: ¥#{c[:amount].to_s}"
    }.join("、")

    <<~PROMPT
      #{year}年#{month}月の家計データを分析してください。

      総支出: ¥#{data[:total_amount]}
      取引件数: #{data[:transaction_count]}件
      カテゴリ別内訳: #{categories_text}

      この月の支出傾向、特筆すべき点、改善アドバイスを自然な文章で述べてください。
    PROMPT
  end

  def insights_prompt(months_data)
    months_text = months_data.map { |m| "#{m[:month]}: ¥#{m[:total_amount]}" }.join("\n")

    <<~PROMPT
      直近の月別支出データを分析してください。

      #{months_text}

      支出トレンドと簡単なアドバイスを自然な文章で述べてください。
    PROMPT
  end
end
