<template lang="pug">
.analytics-page
  .month-navigation
    .nav-controls
      button.nav-btn(@click="previousMonth" :disabled="!canGoPrevious")
        span.arrow ←
      .month-selector(@click="showMonthPicker = !showMonthPicker")
        span.selected-month {{ formattedCurrentMonth }}
        span.dropdown-arrow {{ showMonthPicker ? '▲' : '▼' }}
      button.nav-btn(@click="nextMonth" :disabled="!canGoNext")
        span.arrow →
    
    .month-picker(v-show="showMonthPicker")
      .year-header {{ currentYear }}年
      .month-grid
        .month-item(
          v-for="month in 12"
          :key="month"
          :class="{ active: month === currentMonth && currentYear === selectedYear, 'has-data': hasDataForMonth(month) }"
          @click="selectMonth(month)"
        ) {{ month }}月

  .stats-cards
    .stat-card
      .stat-title 選択期間の総支出
      .stat-value {{ formatCurrency(statsData.totalAmount) }}
    .stat-card.red
      .stat-title 最も高い支出
      .stat-value {{ formatCurrency(statsData.maxAmount) }}
    .stat-card.green
      .stat-title 1日平均支出
      .stat-value {{ formatCurrency(statsData.averageDaily) }}
    .stat-card.orange
      .stat-title 取引件数
      .stat-value {{ statsData.transactionCount }}件
  
  .analytics-grid
    .chart-section
      .chart-title カテゴリ別支出割合
      .chart-container
        canvas(ref="categoryPieChart")
    
    .chart-section
      .chart-title 日別支出推移
      .chart-container
        canvas(ref="dailyLineChart")
  
  .details-section.full-width
    .chart-title 取引明細
    .filter-bar
      select.filter-select
        option 全カテゴリ
        option 投資
        option 食費
        option 日用品費
        option 娯楽費
        option 住宅費
        option 交通費
        option その他
      select.filter-select
        option 金額順（高い順）
        option 金額順（安い順）
        option 日付順（新しい順）
        option 日付順（古い順）
    
    .table-container
      table.transaction-table
        thead
          tr
            th 日付
            th 店舗・サービス
            th カテゴリ
            th 金額
        tbody
          tr(v-for="(transaction, index) in transactions" :key="index")
            td {{ transaction.date }}
            td {{ transaction.store }}
            td
              CategoryTag(
                :category="transaction.category"
                :categoryText="transaction.categoryText"
                @change-category="handleCategoryChange(index, $event)"
              )
            td.amount {{ transaction.amount }}
</template>

<script>
import { ref, onMounted, computed, reactive } from 'vue'
import { Chart, registerables } from 'chart.js'
import CategoryTag from './CategoryTag.vue'
import apiService from '../services/api.js'

Chart.register(...registerables)

export default {
  name: 'AnalyticsPage',
  components: {
    CategoryTag
  },
  setup() {
    const categoryPieChart = ref(null)
    const dailyLineChart = ref(null)
    
    // 月選択の状態
    const currentYear = ref(new Date().getFullYear())
    const currentMonth = ref(new Date().getMonth() + 1)
    const selectedYear = ref(new Date().getFullYear())
    const showMonthPicker = ref(false)
    const availableMonths = ref([]) // データがある月の配列
    const initialDataLoaded = ref(false)
    
    // 統計データ
    const statsData = reactive({
      totalAmount: 0,
      maxAmount: 0,
      averageDaily: 0,
      transactionCount: 0
    })
    
    // サンプルデータ
    const transactions = ref([
      {
        date: '2024/08/10',
        store: 'Amazon.co.jp',
        category: 'other',
        categoryText: 'その他',
        amount: '￥48,500'
      },
      {
        date: '2024/08/09',
        store: '楽天証券',
        category: 'investment',
        categoryText: '投資',
        amount: '￥45,000'
      },
      {
        date: '2024/08/08',
        store: 'イオンモール',
        category: 'food',
        categoryText: '食費',
        amount: '￥12,450'
      },
      {
        date: '2024/08/07',
        store: 'Netflix',
        category: 'entertainment',
        categoryText: '娯楽費',
        amount: '￥1,490'
      },
      {
        date: '2024/08/06',
        store: 'JR東日本',
        category: 'transport',
        categoryText: '交通費',
        amount: '￥1,340'
      },
      {
        date: '2024/08/05',
        store: '住宅管理会社',
        category: 'housing',
        categoryText: '住宅費',
        amount: '￥8,920'
      },
      {
        date: '2024/08/04',
        store: 'スターバックス',
        category: 'food',
        categoryText: '食費',
        amount: '￥890'
      },
      {
        date: '2024/08/03',
        store: 'Spotify',
        category: 'daily',
        categoryText: '日用品費',
        amount: '￥980'
      }
    ])
    
    const createCharts = () => {
      // カテゴリ別円グラフ
      const pieCtx = categoryPieChart.value.getContext('2d')
      new Chart(pieCtx, {
        type: 'doughnut',
        data: {
          labels: ['投資', '食費', '日用品費', '娯楽費', '住宅費', '交通費', 'その他'],
          datasets: [{
            data: [531000, 424000, 298000, 211000, 108000, 166000, 286000],
            backgroundColor: [
              '#FF6384',
              '#4BC0C0', 
              '#9966FF',
              '#36A2EB',
              '#FF9F40',
              '#FFCE56',
              '#C9CBCF'
            ],
            borderWidth: 2,
            borderColor: '#fff'
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: {
              position: 'bottom',
              labels: {
                usePointStyle: true,
                padding: 15,
                font: { size: 11 }
              }
            },
            tooltip: {
              callbacks: {
                label: function(context) {
                  const total = context.dataset.data.reduce((a, b) => a + b, 0)
                  const percentage = ((context.parsed * 100) / total).toFixed(1)
                  return context.label + ': ￥' + context.parsed.toLocaleString() + ' (' + percentage + '%)'
                }
              }
            }
          }
        }
      })

      // 日別推移線グラフ
      const lineCtx = dailyLineChart.value.getContext('2d')
      new Chart(lineCtx, {
        type: 'line',
        data: {
          labels: ['8/1', '8/2', '8/3', '8/4', '8/5', '8/6', '8/7', '8/8', '8/9', '8/10'],
          datasets: [{
            label: '日別支出',
            data: [4200, 8900, 2340, 12450, 8920, 1340, 1490, 12450, 45000, 48500],
            borderColor: '#4CAF50',
            backgroundColor: 'rgba(76, 175, 80, 0.1)',
            borderWidth: 2,
            fill: true,
            tension: 0.4
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          scales: {
            y: {
              beginAtZero: true,
              ticks: {
                callback: function(value) {
                  return '￥' + value.toLocaleString()
                }
              }
            }
          },
          plugins: {
            legend: { display: false },
            tooltip: {
              callbacks: {
                label: function(context) {
                  return '支出: ￥' + context.parsed.y.toLocaleString()
                }
              }
            }
          }
        }
      })
    }
    
    const handleCategoryChange = (index, newCategory) => {
      transactions.value[index].category = newCategory.category
      transactions.value[index].categoryText = newCategory.text
    }
    
    // 月選択機能
    const formattedCurrentMonth = computed(() => {
      return `${currentYear.value}年${currentMonth.value}月`
    })
    
    const canGoPrevious = computed(() => {
      // 最初の取引データがある月まで戻れるかチェック
      return availableMonths.value.length > 0
    })
    
    const canGoNext = computed(() => {
      const now = new Date()
      return !(currentYear.value === now.getFullYear() && currentMonth.value === now.getMonth() + 1)
    })
    
    const hasDataForMonth = (month) => {
      const monthKey = `${currentYear.value}-${month.toString().padStart(2, '0')}`
      return availableMonths.value.some(date => date.startsWith(monthKey))
    }
    
    const previousMonth = () => {
      if (currentMonth.value === 1) {
        currentMonth.value = 12
        currentYear.value--
      } else {
        currentMonth.value--
      }
      loadMonthData()
    }
    
    const nextMonth = () => {
      if (currentMonth.value === 12) {
        currentMonth.value = 1
        currentYear.value++
      } else {
        currentMonth.value++
      }
      loadMonthData()
    }
    
    const selectMonth = (month) => {
      if (hasDataForMonth(month)) {
        currentMonth.value = month
        showMonthPicker.value = false
        loadMonthData()
      }
    }
    
    // 月次データ読み込み
    const loadMonthData = async () => {
      try {
        // 月次データを取得
        const monthlyData = await apiService.getMonthlyData(currentYear.value, currentMonth.value)
        
        // 統計データ更新
        statsData.totalAmount = monthlyData.total_amount || 0
        statsData.transactionCount = monthlyData.transaction_count || 0
        statsData.averageDaily = monthlyData.total_amount ? Math.round(monthlyData.total_amount / new Date(currentYear.value, currentMonth.value, 0).getDate()) : 0
        
        // 取引データを取得
        const transactionData = await apiService.getTransactions({
          month: `${currentYear.value}-${currentMonth.value.toString().padStart(2, '0')}`
        })
        
        transactions.value = transactionData.transactions.map(t => ({
          date: new Date(t.transaction_date).toLocaleDateString('ja-JP'),
          store: t.store_name,
          category: t.category?.name || 'その他',
          categoryText: t.category?.name || 'その他',
          amount: formatCurrency(t.amount),
          id: t.id
        }))
        
        // 最大支出を計算
        if (transactions.value.length > 0) {
          const amounts = transactions.value.map(t => parseFloat(t.amount.replace(/[^\d]/g, '')))
          statsData.maxAmount = Math.max(...amounts)
        }
        
        // チャートを更新
        updateCharts()
        
      } catch (error) {
        console.error('月次データ読み込みエラー:', error)
      }
    }
    
    // 利用可能な月を取得
    const loadAvailableMonths = async () => {
      try {
        const analyticsData = await apiService.getAnalyticsData()
        availableMonths.value = Object.keys(analyticsData.daily_totals || {})
        
        // データがある場合、最新の月をデフォルトに設定
        if (availableMonths.value.length > 0 && !initialDataLoaded.value) {
          const sortedDates = availableMonths.value.sort()
          const latestDate = sortedDates[sortedDates.length - 1]
          const date = new Date(latestDate)
          
          currentYear.value = date.getFullYear()
          currentMonth.value = date.getMonth() + 1
          initialDataLoaded.value = true
          
          // 最新の月のデータを読み込み
          await loadMonthData()
        }
      } catch (error) {
        console.error('利用可能月データ読み込みエラー:', error)
      }
    }
    
    const formatCurrency = (amount) => {
      return '￥' + Math.round(amount).toLocaleString()
    }
    
    // チャート更新処理
    const updateCharts = async () => {
      try {
        // カテゴリ別集計データを取得
        const monthlyData = await apiService.getMonthlyData(currentYear.value, currentMonth.value)
        
        // 円グラフ用データ
        const categoryData = monthlyData.category_totals || []
        const categoryLabels = categoryData.map(cat => cat.category)
        const categoryAmounts = categoryData.map(cat => cat.total)
        const categoryColors = categoryData.map(cat => cat.color)
        
        // 円グラフを更新
        if (categoryPieChart.value) {
          categoryPieChart.value.destroy()
        }
        
        if (categoryData.length > 0) {
          const ctx1 = categoryPieChart.value?.getContext('2d')
          if (ctx1) {
            categoryPieChart.value = new Chart(ctx1, {
              type: 'doughnut',
              data: {
                labels: categoryLabels,
                datasets: [{
                  data: categoryAmounts,
                  backgroundColor: categoryColors,
                  borderWidth: 2,
                  borderColor: '#fff'
                }]
              },
              options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                  legend: { display: false }
                }
              }
            })
          }
        }
        
        // 日別推移データ
        const analyticsData = await apiService.getAnalyticsData(
          `${currentYear.value}-${currentMonth.value.toString().padStart(2, '0')}-01`,
          `${currentYear.value}-${currentMonth.value.toString().padStart(2, '0')}-${new Date(currentYear.value, currentMonth.value, 0).getDate()}`
        )
        
        const dailyData = analyticsData.daily_totals || {}
        const sortedDates = Object.keys(dailyData).sort()
        const dailyLabels = sortedDates.map(date => {
          const d = new Date(date)
          return `${d.getMonth() + 1}/${d.getDate()}`
        })
        const dailyAmounts = sortedDates.map(date => dailyData[date] || 0)
        
        // 線グラフを更新
        if (dailyLineChart.value) {
          dailyLineChart.value.destroy()
        }
        
        if (sortedDates.length > 0) {
          const ctx2 = dailyLineChart.value?.getContext('2d')
          if (ctx2) {
            dailyLineChart.value = new Chart(ctx2, {
              type: 'line',
              data: {
                labels: dailyLabels,
                datasets: [{
                  label: '支出額',
                  data: dailyAmounts,
                  borderColor: '#4CAF50',
                  backgroundColor: 'rgba(76, 175, 80, 0.1)',
                  tension: 0.4,
                  fill: true,
                  pointBackgroundColor: '#4CAF50',
                  pointBorderColor: '#fff',
                  pointBorderWidth: 2
                }]
              },
              options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                  y: {
                    beginAtZero: true,
                    ticks: {
                      callback: function(value) {
                        return '¥' + value.toLocaleString()
                      }
                    }
                  }
                },
                plugins: {
                  legend: { display: false }
                }
              }
            })
          }
        }
        
      } catch (error) {
        console.error('チャート更新エラー:', error)
      }
    }

    onMounted(() => {
      loadAvailableMonths()
    })
    
    return {
      categoryPieChart,
      dailyLineChart,
      transactions,
      currentYear,
      currentMonth,
      selectedYear,
      showMonthPicker,
      statsData,
      initialDataLoaded,
      formattedCurrentMonth,
      canGoPrevious,
      canGoNext,
      hasDataForMonth,
      previousMonth,
      nextMonth,
      selectMonth,
      formatCurrency,
      handleCategoryChange,
      updateCharts
    }
  }
}
</script>

<style lang="scss" scoped>
.analytics-page {
  
}

.month-navigation {
  background: white;
  border-radius: 10px;
  padding: 20px;
  margin-bottom: 20px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
  position: relative;
}

.nav-controls {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 20px;
}

.nav-btn {
  background: #f8f9fa;
  border: 1px solid #dee2e6;
  border-radius: 50%;
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.3s ease;
  
  &:hover:not(:disabled) {
    background: #4CAF50;
    color: white;
    border-color: #4CAF50;
  }
  
  &:disabled {
    opacity: 0.3;
    cursor: not-allowed;
  }
  
  .arrow {
    font-size: 1.2em;
    font-weight: bold;
  }
}

.month-selector {
  background: #f8f9fa;
  border: 1px solid #dee2e6;
  border-radius: 8px;
  padding: 10px 15px;
  cursor: pointer;
  user-select: none;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 140px;
  justify-content: space-between;
  
  &:hover {
    background: #e9ecef;
  }
  
  .selected-month {
    font-weight: 600;
  }
  
  .dropdown-arrow {
    font-size: 0.8em;
    color: #6c757d;
  }
}

.month-picker {
  position: absolute;
  top: 100%;
  left: 50%;
  transform: translateX(-50%);
  background: white;
  border: 1px solid #dee2e6;
  border-radius: 10px;
  padding: 20px;
  margin-top: 10px;
  box-shadow: 0 4px 20px rgba(0,0,0,0.15);
  z-index: 100;
  min-width: 280px;
}

.year-header {
  text-align: center;
  font-size: 1.1em;
  font-weight: 600;
  margin-bottom: 15px;
  color: #333;
}

.month-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 10px;
}

.month-item {
  padding: 8px;
  text-align: center;
  border: 1px solid #dee2e6;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.3s ease;
  font-size: 0.9em;
  
  &:hover {
    background: #f8f9fa;
  }
  
  &.has-data {
    background: #e8f5e8;
    border-color: #4CAF50;
    color: #2e7d2e;
    font-weight: 600;
    
    &:hover {
      background: #d4edda;
    }
  }
  
  &.active {
    background: #4CAF50;
    color: white;
    border-color: #4CAF50;
  }
  
  &:not(.has-data) {
    opacity: 0.4;
    cursor: not-allowed;
  }
}

.analytics-page {
  
}

.stats-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 20px;
  margin-bottom: 30px;
}

.stat-card {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 20px;
  border-radius: 10px;
  text-align: center;
  
  &.red {
    background: linear-gradient(135deg, #ff7675 0%, #fd79a8 100%);
  }
  
  &.green {
    background: linear-gradient(135deg, #00b894 0%, #00cec9 100%);
  }
  
  &.orange {
    background: linear-gradient(135deg, #e17055 0%, #fdcb6e 100%);
  }
}

.stat-title {
  font-size: 0.9em;
  opacity: 0.9;
  margin-bottom: 10px;
}

.stat-value {
  font-size: 1.8em;
  font-weight: bold;
}

.analytics-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 30px;
  margin-bottom: 30px;
}

.chart-section {
  background: white;
  border-radius: 10px;
  padding: 25px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}

.chart-title {
  font-size: 1.3em;
  color: #333;
  margin-bottom: 20px;
  padding-bottom: 10px;
  border-bottom: 2px solid #f8f9fa;
}

.chart-container {
  position: relative;
  height: 300px;
}

.details-section {
  background: white;
  border-radius: 10px;
  padding: 25px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
  margin-bottom: 30px;
  overflow: visible;
  
  &.full-width {
    grid-column: 1 / -1;
  }
}

.filter-bar {
  display: flex;
  gap: 15px;
  margin-bottom: 20px;
  flex-wrap: wrap;
}

.filter-select {
  padding: 8px 15px;
  border: 1px solid #dee2e6;
  border-radius: 5px;
  background: white;
  font-size: 0.9em;
}

.transaction-table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 20px;
}

.table-container {
  overflow: visible;
  position: relative;
}

.transaction-table th {
  background: #f8f9fa;
  padding: 12px;
  text-align: left;
  border-bottom: 2px solid #dee2e6;
  font-weight: 600;
}

.transaction-table td {
  padding: 10px 12px;
  border-bottom: 1px solid #dee2e6;
}

.transaction-table tr:hover {
  background: #f8f9fa;
}

.transaction-table tr {
  position: relative;
}

.amount {
  font-weight: bold;
  text-align: right;
}
</style>