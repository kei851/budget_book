// API設定
const API_BASE_URL = 'http://localhost:3001/api/v1'

class ApiService {
  constructor() {
    this.baseURL = API_BASE_URL
  }

  // CSVファイルをアップロードしてインポート
  async uploadCsv(file, clearExisting = true) {
    const formData = new FormData()
    formData.append('csv_file', file)
    formData.append('clear_existing', clearExisting.toString())

    const response = await fetch(`${this.baseURL}/transactions/import`, {
      method: 'POST',
      body: formData,
      headers: {
        'Accept': 'application/json'
      }
    })

    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.error || 'アップロードに失敗しました')
    }

    return await response.json()
  }

  // 取引データ一覧取得
  async getTransactions(params = {}) {
    const queryParams = new URLSearchParams()
    
    Object.keys(params).forEach(key => {
      if (params[key] !== null && params[key] !== undefined) {
        queryParams.append(key, params[key])
      }
    })

    const response = await fetch(`${this.baseURL}/transactions?${queryParams}`)
    
    if (!response.ok) {
      throw new Error('データの取得に失敗しました')
    }

    return await response.json()
  }

  // 月次集計データ取得
  async getMonthlyData(year = null, month = null) {
    const params = new URLSearchParams()
    if (year) params.append('year', year)
    if (month) params.append('month', month)

    const response = await fetch(`${this.baseURL}/transactions/monthly?${params}`)
    
    if (!response.ok) {
      throw new Error('月次データの取得に失敗しました')
    }

    return await response.json()
  }

  // 分析データ取得
  async getAnalyticsData(startDate = null, endDate = null) {
    const params = new URLSearchParams()
    if (startDate) params.append('start_date', startDate)
    if (endDate) params.append('end_date', endDate)

    const response = await fetch(`${this.baseURL}/transactions/analytics?${params}`)
    
    if (!response.ok) {
      throw new Error('分析データの取得に失敗しました')
    }

    return await response.json()
  }

  // カテゴリ一覧取得
  async getCategories() {
    const response = await fetch(`${this.baseURL}/categories`)
    
    if (!response.ok) {
      throw new Error('カテゴリデータの取得に失敗しました')
    }

    return await response.json()
  }

  // 取引データ更新
  async updateTransaction(id, data) {
    const response = await fetch(`${this.baseURL}/transactions/${id}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify({ transaction: data })
    })

    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.errors?.join(', ') || '更新に失敗しました')
    }

    return await response.json()
  }
}

export default new ApiService()