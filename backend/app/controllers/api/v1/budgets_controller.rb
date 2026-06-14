module Api
  module V1
    class BudgetsController < ApplicationController
      # GET /api/v1/budgets?year=2025&month=5
      def index
        year = params[:year]&.to_i || Time.current.year
        month = params[:month]&.to_i || Time.current.month

        budgets = Budget.for_month(year, month).includes(:category)
        actuals = actual_spending(year, month)

        render json: budgets.map { |b|
          spent = actuals[b.category_id] || 0
          {
            id: b.id,
            category_id: b.category_id,
            category_name: b.category.name,
            category_color: b.category.color,
            budget_amount: b.amount,
            spent_amount: spent,
            remaining: b.amount - spent,
            percentage: b.amount > 0 ? [(spent / b.amount * 100).round, 100].min : 0
          }
        }
      end

      # PUT /api/v1/budgets/set_month  { year:, month:, budgets: [{category_id:, amount:}] }
      def set_month
        year = params[:year].to_i
        month = params[:month].to_i
        items = params[:budgets] || []

        saved = []
        items.each do |item|
          budget = Budget.find_or_initialize_by(
            category_id: item[:category_id], year: year, month: month
          )
          budget.amount = item[:amount].to_f
          if budget.amount > 0
            budget.save!
            saved << budget
          else
            budget.destroy if budget.persisted?
          end
        end

        render json: { saved: saved.length }
      rescue => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def actual_spending(year, month)
        start_date = Date.new(year, month, 1)
        end_date = start_date.end_of_month
        Transaction
          .where(transaction_date: start_date..end_date)
          .group(:category_id)
          .sum(:amount)
      end
    end
  end
end
