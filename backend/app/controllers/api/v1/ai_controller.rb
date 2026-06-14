module Api
  module V1
    class AiController < ApplicationController
      include ActionController::Live

      TOOLS = [
        {
          name: "record_transaction",
          description: "支出を家計簿に記録する。ユーザーが現金払いや支出を伝えた時に使う。",
          input_schema: {
            type: "object",
            properties: {
              store_name:       { type: "string",  description: "店舗名・内容（例: コンビニ、居酒屋）" },
              amount:           { type: "integer", description: "金額（円、正の整数）" },
              transaction_date: { type: "string",  description: "日付 YYYY-MM-DD。不明なら今日の日付" },
              payment_method:   { type: "string",  enum: ["cash", "pasmo", "other"] },
              category_id:      { type: "integer", description: "カテゴリID: 1=投資, 2=食費, 3=日用品費, 4=娯楽費, 5=住宅費, 6=交通費, 7=その他。不明なら省略" }
            },
            required: ["store_name", "amount", "transaction_date"]
          }
        }
      ].freeze

      def monthly_summary
        year = params[:year].to_i
        month = params[:month].to_i

        if year.zero? || month.zero?
          return render json: { error: "year と month は必須です" }, status: :bad_request
        end

        service = AiInsightService.new
        summary = service.monthly_summary(year, month)

        if summary
          render json: { summary: summary }
        else
          render json: { summary: nil, message: "該当月のデータがないか、AI生成に失敗しました" }
        end
      end

      def reclassify
        unclassified = Transaction.where(category_id: nil)

        if unclassified.empty?
          return render json: { reclassified_count: 0, message: "未分類の取引はありません" }
        end

        store_names = unclassified.pluck(:store_name).uniq
        ai_results = AiCategoryClassifierService.new.classify_batch(store_names)

        reclassified_count = 0
        unclassified.each do |t|
          cat_id = ai_results[t.store_name]
          if cat_id
            t.update(category_id: cat_id, auto_classified: true)
            reclassified_count += 1
          end
        end

        render json: {
          reclassified_count: reclassified_count,
          total_unclassified: unclassified.count,
          message: "#{reclassified_count}件を再分類しました"
        }
      end

      def chat
        response.headers["Content-Type"] = "text/event-stream"
        response.headers["Cache-Control"] = "no-cache"
        response.headers["X-Accel-Buffering"] = "no"
        response.headers["Access-Control-Allow-Origin"] = "http://localhost:3002"

        messages = (params[:messages] || []).map do |m|
          { role: m[:role], content: m[:content] }
        end

        context = AiInsightService.new.build_context_for_chat
        client = Anthropic::Client.new(api_key: ENV.fetch("ANTHROPIC_API_KEY"))

        result = client.messages.create(
          model: "claude-opus-4-5",
          max_tokens: 2048,
          tools: TOOLS,
          system_: build_system_prompt(context),
          messages: messages
        )

        if result.stop_reason == 'tool_use'
          tool_block = result.content.find { |b| b.type == 'tool_use' }
          if tool_block&.name == 'record_transaction'
            input = tool_block.input
            category = Category.find_by(id: input['category_id']) ||
                       CategoryRule.find_category_for_store(input['store_name'])
            Transaction.create!(
              store_name: input['store_name'],
              amount: input['amount'].to_i,
              transaction_date: Date.parse(input['transaction_date']),
              payment_method: input.fetch('payment_method', 'cash'),
              category: category,
              auto_classified: category.present?
            )
            amount_formatted = input['amount'].to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
            msg = "✅ #{input['store_name']} ¥#{amount_formatted}を記録しました"
            response.stream.write("data: #{{ type: 'tool_result', message: msg }.to_json}\n\n")
          end
        else
          text_content = result.content.select { |b| b.type == 'text' }.map(&:text).join
          response.stream.write("data: #{text_content.to_json}\n\n")
        end

        response.stream.write("data: [DONE]\n\n")
      rescue ActionController::Live::ClientDisconnected
        # クライアント切断は正常終了
      rescue => e
        Rails.logger.error "チャットSSEエラー: #{e.message}"
        response.stream.write("data: #{e.message.to_json}\n\n") rescue nil
      ensure
        response.stream.close
      end

      private

      def build_system_prompt(context)
        category_text = context[:category_breakdown]&.map { |c|
          "#{c[:category]}:¥#{c[:amount]}"
        }&.join("、") || "不明"

        today = Date.today.strftime('%Y-%m-%d')

        <<~PROMPT.strip
          あなたは親切な家計管理アドバイザーです。ユーザーの家計相談に日本語で丁寧に答えてください。
          現金の支出など家計への記録依頼があれば、record_transactionツールを使って家計簿に保存してください。

          今日の日付: #{today}

          現在の家計状況（#{context[:current_month]}）:
          - 今月の総支出: ¥#{context[:total_amount] || '不明'}
          - 取引件数: #{context[:transaction_count] || '不明'}件
          - カテゴリ別支出: #{category_text}

          具体的なアドバイスと改善提案を提供してください。回答は簡潔で実践的にしてください。
        PROMPT
      end
    end
  end
end
