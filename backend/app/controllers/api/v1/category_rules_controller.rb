class Api::V1::CategoryRulesController < ApplicationController
  before_action :set_category_rule, only: [:update, :destroy]
  
  def index
    @category_rules = CategoryRule.includes(:category).by_priority
    
    render json: {
      category_rules: @category_rules.map do |rule|
        # キーワードにマッチするトランザクション数を計算
        normalized_keyword = CategoryRule.normalize_text(rule.keyword)
        matching_count = Transaction.where(
          "LOWER(REPLACE(REPLACE(REPLACE(store_name, '-', ''), '‐', ''), ' ', '')) LIKE ?", 
          "%#{normalized_keyword}%"
        ).count
        
        {
          id: rule.id,
          keyword: rule.keyword,
          category_id: rule.category_id,
          category_name: rule.category.name,
          category_color: rule.category.color,
          priority: rule.priority,
          matching_count: matching_count,
          created_at: rule.created_at,
          updated_at: rule.updated_at
        }
      end
    }
  end

  def create
    @category_rule = CategoryRule.new(category_rule_params)
    
    if @category_rule.save
      render json: {
        id: @category_rule.id,
        keyword: @category_rule.keyword,
        category_id: @category_rule.category_id,
        category_name: @category_rule.category.name,
        category_color: @category_rule.category.color,
        priority: @category_rule.priority
      }, status: :created
    else
      render json: { errors: @category_rule.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @category_rule.update(category_rule_params)
      render json: {
        id: @category_rule.id,
        keyword: @category_rule.keyword,
        category_id: @category_rule.category_id,
        category_name: @category_rule.category.name,
        category_color: @category_rule.category.color,
        priority: @category_rule.priority
      }
    else
      render json: { errors: @category_rule.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @category_rule.destroy
    head :no_content
  end

  def bulk_update
    begin
      keyword = params[:keyword]
      new_category_id = params[:new_category_id]
      
      if keyword.blank? || new_category_id.blank?
        return render json: { error: 'キーワードとカテゴリIDが必要です' }, status: :bad_request
      end
      
      category = Category.find_by(id: new_category_id)
      unless category
        return render json: { error: 'カテゴリが見つかりません' }, status: :not_found
      end
      
      # キーワードの正規化
      normalized_keyword = CategoryRule.normalize_text(keyword)
      
      # 該当キーワードを含む取引を一括更新 (SQLite互換)
      transactions = Transaction.where(
        "LOWER(REPLACE(REPLACE(REPLACE(store_name, '-', ''), '‐', ''), ' ', '')) LIKE ?", 
        "%#{normalized_keyword}%"
      )
      updated_count = transactions.update_all(category_id: new_category_id)
      
      render json: {
        message: "#{updated_count}件の取引のカテゴリを「#{category.name}」に更新しました",
        updated_count: updated_count,
        category_name: category.name
      }
    rescue StandardError => e
      Rails.logger.error "Bulk update error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { error: '一括更新中にエラーが発生しました' }, status: :internal_server_error
    end
  end

  private

  def set_category_rule
    @category_rule = CategoryRule.find(params[:id])
  end

  def category_rule_params
    params.require(:category_rule).permit(:keyword, :category_id, :priority)
  end
end
