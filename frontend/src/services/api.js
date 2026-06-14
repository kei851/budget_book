const API_BASE_URL = 'http://localhost:3001/api/v1'

class ApiService {
  constructor() {
    this.baseURL = API_BASE_URL
  }

  async uploadCsv(file, clearExisting = false) {
    const formData = new FormData()
    formData.append('csv_file', file)
    formData.append('clear_existing', clearExisting.toString())
    const response = await fetch(`${this.baseURL}/transactions/import`, {
      method: 'POST',
      body: formData,
      headers: { 'Accept': 'application/json' }
    })
    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.error || 'アップロードに失敗しました')
    }
    return await response.json()
  }

  async getTransactions(params = {}) {
    const queryParams = new URLSearchParams()
    Object.keys(params).forEach(key => {
      if (params[key] !== null && params[key] !== undefined) queryParams.append(key, params[key])
    })
    const response = await fetch(`${this.baseURL}/transactions?${queryParams}`)
    if (!response.ok) throw new Error('データの取得に失敗しました')
    return await response.json()
  }

  async getMonthlyData(year = null, month = null) {
    const params = new URLSearchParams()
    if (year) params.append('year', year)
    if (month) params.append('month', month)
    const response = await fetch(`${this.baseURL}/transactions/monthly?${params}`)
    if (!response.ok) throw new Error('月次データの取得に失敗しました')
    return await response.json()
  }

  async getAnalyticsData(startDate = null, endDate = null) {
    const params = new URLSearchParams()
    if (startDate) params.append('start_date', startDate)
    if (endDate) params.append('end_date', endDate)
    const response = await fetch(`${this.baseURL}/transactions/analytics?${params}`)
    if (!response.ok) throw new Error('分析データの取得に失敗しました')
    return await response.json()
  }

  async getCategories() {
    const response = await fetch(`${this.baseURL}/categories`)
    if (!response.ok) throw new Error('カテゴリデータの取得に失敗しました')
    return await response.json()
  }

  async updateTransaction(id, data) {
    const response = await fetch(`${this.baseURL}/transactions/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
      body: JSON.stringify({ transaction: data })
    })
    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.errors?.join(', ') || '更新に失敗しました')
    }
    return await response.json()
  }

  async getUploadHistories() {
    const response = await fetch(`${this.baseURL}/upload_histories`)
    if (!response.ok) throw new Error('履歴データの取得に失敗しました')
    return await response.json()
  }

  async getUploadHistory(id) {
    const response = await fetch(`${this.baseURL}/upload_histories/${id}`)
    if (!response.ok) throw new Error('履歴データの取得に失敗しました')
    return await response.json()
  }

  async deleteUploadHistory(id) {
    const response = await fetch(`${this.baseURL}/upload_histories/${id}`, {
      method: 'DELETE',
      headers: { 'Accept': 'application/json' }
    })
    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.error || '削除に失敗しました')
    }
    return await response.json()
  }

  async getCategoryRules() {
    const response = await fetch(`${this.baseURL}/category_rules`)
    if (!response.ok) throw new Error('カテゴリルールの取得に失敗しました')
    return await response.json()
  }

  async createCategoryRule(ruleData) {
    const response = await fetch(`${this.baseURL}/category_rules`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
      body: JSON.stringify({ category_rule: ruleData })
    })
    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.errors?.join(', ') || 'ルールの作成に失敗しました')
    }
    return await response.json()
  }

  async updateCategoryRule(id, ruleData) {
    const response = await fetch(`${this.baseURL}/category_rules/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
      body: JSON.stringify({ category_rule: ruleData })
    })
    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.errors?.join(', ') || 'ルールの更新に失敗しました')
    }
    return await response.json()
  }

  async deleteCategoryRule(id) {
    const response = await fetch(`${this.baseURL}/category_rules/${id}`, {
      method: 'DELETE',
      headers: { 'Accept': 'application/json' }
    })
    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.error || 'ルールの削除に失敗しました')
    }
    return true
  }

  async getBudgets(year, month) {
    const response = await fetch(`${this.baseURL}/budgets?year=${year}&month=${month}`)
    if (!response.ok) throw new Error('予算データの取得に失敗しました')
    return await response.json()
  }

  async setBudgets(year, month, budgets) {
    const response = await fetch(`${this.baseURL}/budgets/set_month`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ year, month, budgets })
    })
    if (!response.ok) throw new Error('予算の保存に失敗しました')
    return await response.json()
  }

  async getMonthlyComparison(year, month) {
    const response = await fetch(`${this.baseURL}/insights/monthly_comparison?year=${year}&month=${month}`)
    if (!response.ok) throw new Error('比較データの取得に失敗しました')
    return await response.json()
  }

  async getRecurring() {
    const response = await fetch(`${this.baseURL}/insights/recurring`)
    if (!response.ok) throw new Error('定期支出データの取得に失敗しました')
    return await response.json()
  }

  async getAiMonthlySummary(year, month) {
    const response = await fetch(`${this.baseURL}/ai/monthly_summary`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
      body: JSON.stringify({ year, month })
    })
    if (!response.ok) throw new Error('AIサマリの生成に失敗しました')
    return await response.json()
  }

  async reclassifyTransactions() {
    const response = await fetch(`${this.baseURL}/ai/reclassify`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' }
    })
    if (!response.ok) throw new Error('AI再分類に失敗しました')
    return await response.json()
  }

  async createTransaction(data) {
    const response = await fetch(`${this.baseURL}/transactions`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
      body: JSON.stringify({ transaction: data })
    })
    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.errors?.join(', ') || '保存に失敗しました')
    }
    return await response.json()
  }

  async bulkUpdateCategory(keyword, newCategoryId) {
    const response = await fetch(`${this.baseURL}/category_rules/bulk_update`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
      body: JSON.stringify({ keyword, new_category_id: newCategoryId })
    })
    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.error || '一括更新に失敗しました')
    }
    return await response.json()
  }
}

export default new ApiService()
