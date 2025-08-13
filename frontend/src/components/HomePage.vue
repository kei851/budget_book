<template lang="pug">
.home-page
  .upload-container
    .upload-section
      .upload-icon 📁
      .upload-text 右の対応済みの形式のファイルをアップロード
      FileUpload(@file-uploaded="handleFileUpload" :loading="loading")
    
    .format-table-section
      h3 対応ファイル形式
      table.format-table
        thead
          tr
            th 取引媒体
            th 形式
            th 対応状況
        tbody
          tr
            td 楽天カード
            td CSV
            td
              span.status.supported ✓ 対応
          tr
            td 楽天銀行
            td CSV
            td
              span.status.planned 予定
          tr
            td エポスカード
            td PDF
            td
              span.status.planned 予定
          tr
            td PayPay
            td CSV
            td
              span.status.planned 予定
  
  .chart-section
    .chart-header
      .chart-title 月毎支出グラフ
      .period-selector
        .period-btn(
          v-for="period in periods" 
          :key="period"
          :class="{ active: selectedPeriod === period }"
          @click="handlePeriodChange(period)"
        ) {{ period }}
    
    ExpenseChart(
      :data="chartData" 
      :period="selectedPeriod"
    )
    
    SummaryCards(:summary="summaryData" @navigate-to-analytics="$emit('navigate', 'analytics')")
</template>

<script>
import { ref, reactive, onMounted } from 'vue'
import FileUpload from './FileUpload.vue'
import ExpenseChart from './ExpenseChart.vue'
import SummaryCards from './SummaryCards.vue'
import apiService from '../services/api.js'

export default {
  name: 'HomePage',
  components: {
    FileUpload,
    ExpenseChart,
    SummaryCards
  },
  emits: ['navigate'],
  setup() {
    const loading = ref(false)
    const selectedPeriod = ref('12ヶ月')
    const periods = ['3ヶ月', '6ヶ月', '12ヶ月', '全期間']
    const uploadSuccess = ref(false)
    
    // リアクティブなデータ
    const chartData = reactive({
      labels: [],
      datasets: []
    })
    
    const summaryData = reactive({
      thisMonth: 0,
      monthlyAverage: 0,
      maxMonth: 0,
      dataCount: 0
    })
    
    // データ読み込み
    const loadData = async () => {
      try {
        const monthlyData = await apiService.getMonthlyData()
        await updateChartData() // チャートデータは別途APIから取得
        updateSummaryData(monthlyData)
      } catch (error) {
        console.error('データ読み込みエラー:', error)
        // データがない場合は空のグラフを表示
        chartData.labels = []
        chartData.datasets = []
      }
    }
    
    // チャートデータ更新
    const updateChartData = async () => {
      try {
        // 過去12ヶ月のデータを取得
        const analyticsData = await apiService.getAnalyticsData()
        
        if (!analyticsData.daily_totals || Object.keys(analyticsData.daily_totals).length === 0) {
          chartData.labels = []
          chartData.datasets = []
          return
        }

        // 月別に集計
        const monthlyData = {}
        const categoryMonthlyData = {}
        
        Object.keys(analyticsData.daily_totals).forEach(date => {
          const d = new Date(date)
          const monthKey = `${d.getFullYear()}-${(d.getMonth() + 1).toString().padStart(2, '0')}`
          
          if (!monthlyData[monthKey]) {
            monthlyData[monthKey] = 0
          }
          monthlyData[monthKey] += analyticsData.daily_totals[date] || 0
        })

        // 月別カテゴリデータも取得（簡易版）
        const monthlyApiData = await apiService.getMonthlyData()
        const categoryTotals = monthlyApiData.category_totals || []
        
        // 月別データをソートして最新12ヶ月分を取得
        const sortedMonths = Object.keys(monthlyData).sort()
        const last12Months = sortedMonths.slice(-12)
        
        chartData.labels = last12Months.map(monthKey => {
          const [year, month] = monthKey.split('-')
          return `${year}/${month}`
        })

        // カテゴリ別データセット作成
        chartData.datasets = categoryTotals.map(cat => ({
          label: cat.category,
          data: last12Months.map(monthKey => {
            // 各月のデータ（簡単のため全期間の平均を使用）
            return Math.round((cat.total / 12) || 0)
          }),
          backgroundColor: cat.color,
          borderWidth: 0
        }))
        
      } catch (error) {
        console.error('チャートデータ更新エラー:', error)
        chartData.labels = []
        chartData.datasets = []
      }
    }
    
    // サマリーデータ更新
    const updateSummaryData = (data) => {
      const currentMonth = new Date().getMonth() + 1
      const currentYear = new Date().getFullYear()
      const currentMonthKey = `${currentYear}-${currentMonth.toString().padStart(2, '0')}-01`
      
      summaryData.thisMonth = data.monthly_totals[currentMonthKey] || 0
      
      const monthlyValues = Object.values(data.monthly_totals)
      summaryData.monthlyAverage = monthlyValues.length > 0 
        ? Math.round(monthlyValues.reduce((a, b) => a + b, 0) / monthlyValues.length) 
        : 0
      summaryData.maxMonth = monthlyValues.length > 0 ? Math.max(...monthlyValues) : 0
      summaryData.dataCount = data.transaction_count || 0
    }
    
    // ファイルアップロード処理
    const handleFileUpload = async (file) => {
      loading.value = true
      uploadSuccess.value = false
      
      try {
        console.log('ファイルアップロード開始:', file.name)
        
        const result = await apiService.uploadCsv(file, true)
        console.log('アップロード完了:', result)
        
        if (result.imported_count > 0) {
          uploadSuccess.value = true
          alert(`${result.imported_count}件のデータを正常にインポートしました！`)
          
          // データを再読み込み
          await loadData()
        } else {
          alert('インポートできるデータが見つかりませんでした。')
        }
        
        if (result.errors && result.errors.length > 0) {
          console.warn('インポート時のエラー:', result.errors)
        }
        
      } catch (error) {
        console.error('アップロードエラー:', error)
        alert(`アップロードに失敗しました: ${error.message}`)
      } finally {
        loading.value = false
      }
    }
    
    const handlePeriodChange = (period) => {
      selectedPeriod.value = period
      console.log('期間変更:', period)
      // TODO: 期間に応じたデータフィルタリング実装
    }
    
    // 初期データ読み込み
    onMounted(() => {
      loadData()
    })
    
    return {
      loading,
      selectedPeriod,
      periods,
      chartData,
      summaryData,
      uploadSuccess,
      handleFileUpload,
      handlePeriodChange
    }
  }
}
</script>

<style lang="scss" scoped>
.home-page {
  
}

.upload-container {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 30px;
  margin-bottom: 30px;
}

.upload-section {
  background: #f8f9fa;
  border: 2px dashed #dee2e6;
  border-radius: 10px;
  padding: 40px;
  text-align: center;
  transition: all 0.3s ease;
  
  &:hover {
    border-color: #4CAF50;
    background: #f0f8ff;
  }
}

.upload-icon {
  font-size: 3em;
  margin-bottom: 20px;
  color: #6c757d;
}

.upload-text {
  font-size: 1.2em;
  color: #495057;
  margin-bottom: 15px;
}

.format-table-section {
  background: white;
  border-radius: 10px;
  padding: 25px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
  
  h3 {
    margin-bottom: 20px;
    color: #333;
    font-size: 1.2em;
  }
}

.format-table {
  width: 100%;
  border-collapse: collapse;
  
  th {
    background: #f8f9fa;
    padding: 12px;
    text-align: left;
    border-bottom: 2px solid #dee2e6;
    font-weight: 600;
    font-size: 0.9em;
  }
  
  td {
    padding: 12px;
    border-bottom: 1px solid #dee2e6;
    font-size: 0.9em;
  }
  
  tr:hover {
    background: #f8f9fa;
  }
}

.status {
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 0.8em;
  font-weight: bold;
  
  &.supported {
    background: #d4edda;
    color: #155724;
  }
  
  &.planned {
    background: #fff3cd;
    color: #856404;
  }
}

.chart-section {
  background: white;
  border-radius: 10px;
  padding: 30px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}

.chart-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 25px;
  border-bottom: 2px solid #f8f9fa;
  padding-bottom: 15px;
}

.chart-title {
  font-size: 1.5em;
  color: #333;
}

.period-selector {
  display: flex;
  gap: 10px;
}

.period-btn {
  background: #e9ecef;
  border: 1px solid #dee2e6;
  padding: 8px 15px;
  border-radius: 20px;
  cursor: pointer;
  transition: all 0.3s ease;
  
  &.active {
    background: #4CAF50;
    color: white;
    border-color: #4CAF50;
  }
  
  &:hover:not(.active) {
    background: #dee2e6;
  }
}
</style>