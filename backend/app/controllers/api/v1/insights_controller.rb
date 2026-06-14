module Api
  module V1
    class InsightsController < ApplicationController
      # GET /api/v1/insights/monthly_comparison?year=2025&month=5
      def monthly_comparison
        year = params[:year].to_i
        month = params[:month].to_i

        current   = month_totals(year, month)
        prev_m    = month_ago(year, month, 1)
        prev_year = month_ago(year, month, 12)

        render json: {
          current:   serialize_month(*current_period(year, month), current),
          prev_month: serialize_month(*current_period(*prev_m), month_totals(*prev_m)),
          prev_year:  serialize_month(*current_period(*prev_year), month_totals(*prev_year))
        }
      end

      # GET /api/v1/insights/recurring
      def recurring
        # 直近6ヶ月で3回以上同じ店舗に出費があるものを定期支出として検出
        six_months_ago = 6.months.ago.to_date

        rows = Transaction
          .where("transaction_date >= ?", six_months_ago)
          .where.not(category_id: nil)
          .select("store_name, category_id, COUNT(DISTINCT strftime('%Y-%m', transaction_date)) as month_count, AVG(amount) as avg_amount, COUNT(*) as total_count")
          .group(:store_name, :category_id)
          .having("month_count >= 3")
          .order("month_count DESC, avg_amount DESC")

        categories = Category.all.index_by(&:id)

        render json: rows.map { |r|
          cat = categories[r.category_id]
          {
            store_name:   r.store_name,
            category_id:  r.category_id,
            category_name: cat&.name,
            category_color: cat&.color,
            month_count:  r.month_count,
            avg_amount:   r.avg_amount.round,
            total_count:  r.total_count,
            estimated_monthly: r.avg_amount.round
          }
        }
      end

      private

      def month_totals(year, month)
        start_date = Date.new(year, month, 1)
        end_date = start_date.end_of_month
        txns = Transaction.where(transaction_date: start_date..end_date)
        total = txns.sum(:amount).round
        by_category = txns.joins("LEFT JOIN categories ON categories.id = transactions.category_id")
          .group("categories.name", "categories.color")
          .sum(:amount)
          .map { |(name, color), amt| { name: name || "未分類", color: color || "#ccc", amount: amt.round } }
          .sort_by { |h| -h[:amount] }
        { total: total, by_category: by_category, count: txns.count }
      end

      def month_ago(year, month, months)
        date = Date.new(year, month, 1) << months
        [date.year, date.month]
      end

      def current_period(year, month)
        [year, month]
      end

      def serialize_month(year, month, data)
        { year: year, month: month, label: "#{year}年#{month}月",
          total: data[:total], by_category: data[:by_category], count: data[:count] }
      end
    end
  end
end
