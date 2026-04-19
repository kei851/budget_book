<template lang="pug">
.analytics-page
  .month-navigation
    .nav-controls
      button.nav-btn(@click="previousMonth" :disabled="!canGoPrevious || isLoading || isNavigating")
        svg(viewBox="0 0 24 24" width="16" height="16")
          path(d="M15 18l-6-6 6-6v12z")

      .month-selector(@click="toggleMonthPicker" :class="{ loading: isLoading || isNavigating }")
        span.selected-month {{ formattedCurrentMonth }}
        span.loading-indicator(v-if="isLoading || isNavigating") 読み込み中...
        span.dropdown-arrow(v-else)
          svg(viewBox="0 0 24 24" width="14" height="14")
            path(d="M7 14l5-5 5 5z" v-if="showMonthPicker")
            path(d="M7 10l5 5 5-5z" v-else)

      button.nav-btn(@click="nextMonth" :disabled="!canGoNext || isLoading || isNavigating")
        svg(viewBox="0 0 24 24" width="16" height="16")
          path(d="M9 18l6-6-6-6v12z")

    .month-picker(v-show="showMonthPicker")
      .year-nav-header
        button.year-btn(@click="previousYear" :disabled="!canGoPreviousYear || isLoading || isNavigating")
          svg(viewBox="0 0 24 24" width="18" height="18")
            path(d="M18 17l-6-5 6-5v10zM12 17l-6-5 6-5v10z")

        .year-display {{ currentYear }}年

        button.year-btn(@click="nextYear" :disabled="!canGoNextYear || isLoading || isNavigating")
          svg(viewBox="0 0 24 24" width="18" height="18")
            path(d="M6 17l6-5-6-5v10zM12 17l6-5-6-5v10z")

      .month-grid
        .month-item(
          v-for="month in 12"
          :key="month"
          :class="{ active: month === currentMonth, 'has-data': hasDataForMonth(month) }"
          @click="hasDataForMonth(month) ? selectMonth(month) : null"
        ) {{ month }}月

  .stats-cards
    .stat-card
      .stat-title 選択期間の総支出
      .stat-value {{ isPrivacyMode ? '¥***' : formatCurrency(statsData.totalAmount) }}

    .stat-card.red
      .stat-title 最も高い支出
      .stat-value {{ isPrivacyMode ? '¥***' : formatCurrency(statsData.maxAmount) }}

    .stat-card.green
      .stat-title 1日平均支出
      .stat-value {{ isPrivacyMode ? '¥***' : formatCurrency(statsData.averageDaily) }}

    .stat-card.orange
      .stat-title 取引件数
      .stat-value {{ statsData.transactionCount }}件

  .analytics-grid
    .chart-section
      .chart-title カテゴリ別支出割合
      .chart-container
        .pie-chart-wrapper
          canvas(ref="categoryPieChart")
          .chart-legend(ref="chartLegend")

    .chart-section
      .chart-title 日別支出推移
      .chart-container
        canvas(ref="dailyLineChart")

  .details-section.full-width
    .chart-title 取引明細

    .filter-bar
      select.filter-select(v-model="selectedCategory" @change="applyFilters")
        option(value="") 全カテゴリ
        option(value="投資") 投資
        option(value="食費") 食費
        option(value="日用品費") 日用品費
        option(value="娯楽費") 娯楽費
        option(value="住宅費") 住宅費
        option(value="交通費") 交通費
        option(value="その他") その他

      select.filter-select(v-model="sortOrder" @change="applyFilters")
        option(value="amount_desc") 金額順（高い順）
        option(value="amount_asc") 金額順（安い順）
        option(value="date_desc") 日付順（新しい順）
        option(value="date_asc") 日付順（古い順）

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
            td.amount {{ isPrivacyMode ? '¥***' : transaction.amount }}
</template>

<script>
import { ref, onMounted, onBeforeUnmount, computed, reactive } from 'vue'
import { Chart, registerables } from 'chart.js'
import CategoryTag from './CategoryTag.vue'
import apiService from '../services/api.js'

Chart.register(...registerables)

export default {
  name: 'AnalyticsPage',
  components: { CategoryTag },
  props: {
    isPrivacyMode: {
      type: Boolean,
      default: false
    },
    chartNavigationState: {
      type: Object,
      default: () => ({
        canGoPrevious: false,
        canGoNext: false,
        totalMonths: 0,
        currentOffset: 0,
        availableMonths: []
      })
    }
  },
  setup(props) {
    const categoryPieChart = ref(null)
    const dailyLineChart = ref(null)
    const categoryChartInstance = ref(null)
    const dailyChartInstance = ref(null)
    const chartLegend = ref(null)

    const currentYear = ref(new Date().getFullYear())
    const currentMonth = ref(new Date().getMonth() + 1)
    const selectedYear = ref(new Date().getFullYear())
    const showMonthPicker = ref(false)
    const availableMonths = ref([])
    const initialDataLoaded = ref(false)
    const isLoading = ref(false)
    const isNavigating = ref(false)
    const dataCache = new Map()

    const statsData = reactive({
      totalAmount: 0,
      maxAmount: 0,
      averageDaily: 0,
      transactionCount: 0
    })

    const transactions = ref([])
    const allTransactions = ref([])
    const selectedCategory = ref('')
    const sortOrder = ref('date_desc')

    const applyFilters = () => {
      let filtered = [...allTransactions.value]

      if (selectedCategory.value) {
        filtered = filtered.filter(t => t.categoryText === selectedCategory.value)
      }

      filtered.sort((a, b) => {
        switch (sortOrder.value) {
          case 'amount_desc':
            return parseFloat(b.amount.replace(/[^\d]/g, '')) - parseFloat(a.amount.replace(/[^\d]/g, ''))
          case 'amount_asc':
            return parseFloat(a.amount.replace(/[^\d]/g, '')) - parseFloat(b.amount.replace(/[^\d]/g, ''))
          case 'date_desc':
            return new Date(b.rawDate) - new Date(a.rawDate)
          case 'date_asc':
            return new Date(a.rawDate) - new Date(a.rawDate)
          default:
            return 0
        }
      })

      transactions.value = filtered
    }

    const handleCategoryChange = async (index, newCategory) => {
      try {
        const transaction = transactions.value[index]
        await apiService.updateTransaction(transaction.id, { category_name: newCategory.text })

        const categoryClassMap = {
          '投資': 'investment', '食費': 'food', '日用品費': 'daily',
          '娯楽費': 'entertainment', '住宅費': 'housing', '交通費': 'transport', 'その他': 'other'
        }
        transactions.value[index].category = categoryClassMap[newCategory.text] || 'other'
        transactions.value[index].categoryText = newCategory.text

        await loadMonthData()
      } catch (error) {
        console.error('カテゴリ更新エラー:', error)
        alert('カテゴリの更新に失敗しました: ' + error.message)
      }
    }

    const formattedCurrentMonth = computed(() => `${currentYear.value}年${currentMonth.value}月`)

    const canGoPrevious = computed(() => {
      if (props.chartNavigationState && props.chartNavigationState.availableMonths.length > 0) {
        const currentMonthKey = `${currentYear.value}/${currentMonth.value.toString().padStart(2, '0')}`
        const chartMonths = props.chartNavigationState.availableMonths
        const currentIndex = chartMonths.indexOf(currentMonthKey)
        if (currentIndex === -1) return chartMonths.some(month => month < currentMonthKey)
        return currentIndex > 0
      }

      if (availableMonths.value.length === 0) return false
      const currentMonthKey = `${currentYear.value}-${currentMonth.value.toString().padStart(2, '0')}`
      const currentIndex = availableMonths.value.indexOf(currentMonthKey)
      if (currentIndex === -1) return availableMonths.value.some(month => month < currentMonthKey)
      return currentIndex > 0
    })

    const canGoNext = computed(() => {
      if (props.chartNavigationState && props.chartNavigationState.availableMonths.length > 0) {
        const currentMonthKey = `${currentYear.value}/${currentMonth.value.toString().padStart(2, '0')}`
        const chartMonths = props.chartNavigationState.availableMonths
        const currentIndex = chartMonths.indexOf(currentMonthKey)
        if (currentIndex === -1) return chartMonths.some(month => month > currentMonthKey)
        return currentIndex < chartMonths.length - 1
      }

      if (availableMonths.value.length === 0) return false
      const currentMonthKey = `${currentYear.value}-${currentMonth.value.toString().padStart(2, '0')}`
      const currentIndex = availableMonths.value.indexOf(currentMonthKey)
      if (currentIndex === -1) return availableMonths.value.some(month => month > currentMonthKey)
      return currentIndex < availableMonths.value.length - 1
    })

    const canGoNextYear = computed(() => currentYear.value < new Date().getFullYear())

    const canGoPreviousYear = computed(() => {
      if (props.chartNavigationState && props.chartNavigationState.availableMonths.length > 0) {
        const oldestYear = parseInt(props.chartNavigationState.availableMonths[0].split('/')[0])
        return currentYear.value > oldestYear
      }
      if (availableMonths.value.length === 0) return false
      const oldestYear = parseInt(availableMonths.value[0].split('-')[0])
      return currentYear.value > oldestYear
    })

    const hasDataForMonth = (month) => {
      if (props.chartNavigationState && props.chartNavigationState.availableMonths.length > 0) {
        const monthKey = `${currentYear.value}/${month.toString().padStart(2, '0')}`
        return props.chartNavigationState.availableMonths.includes(monthKey)
      }
      const monthKey = `${currentYear.value}-${month.toString().padStart(2, '0')}`
      return availableMonths.value.includes(monthKey)
    }

    const withNavGuard = async (fn, delay = 200) => {
      if (isLoading.value || isNavigating.value) return
      isNavigating.value = true
      try { await fn() } finally { setTimeout(() => { isNavigating.value = false }, delay) }
    }

    const previousMonth = () => withNavGuard(async () => {
      if (currentMonth.value === 1) { currentMonth.value = 12; currentYear.value-- }
      else { currentMonth.value-- }
      await loadMonthData()
    }, 500)

    const nextMonth = () => withNavGuard(async () => {
      if (currentMonth.value === 12) { currentMonth.value = 1; currentYear.value++ }
      else { currentMonth.value++ }
      await loadMonthData()
    }, 500)

    const toggleMonthPicker = () => { showMonthPicker.value = !showMonthPicker.value }

    const selectMonth = (month) => withNavGuard(async () => {
      if (currentMonth.value === month) { showMonthPicker.value = false; return }
      currentMonth.value = month
      showMonthPicker.value = false
      await loadMonthData()
    })

    const previousYear = () => withNavGuard(async () => { currentYear.value--; await loadMonthData() })

    const nextYear = () => {
      if (canGoNextYear.value) withNavGuard(async () => { currentYear.value++; await loadMonthData() })
    }

    const loadAvailableMonths = async () => {
      try {
        const analyticsData = await apiService.getAnalyticsData()
        const monthSet = new Set()
        analyticsData.category_stats?.forEach(c => {
          Object.keys(c.monthly_data || {}).forEach(key => {
            const [y, m] = key.split('-')
            monthSet.add(`${y}-${m}`)
          })
        })
        availableMonths.value = Array.from(monthSet).sort()

        if (availableMonths.value.length > 0) {
          const latest = availableMonths.value[availableMonths.value.length - 1]
          const [y, m] = latest.split('-')
          currentYear.value = parseInt(y)
          currentMonth.value = parseInt(m)
        }
        initialDataLoaded.value = true
        await loadMonthData()
      } catch (error) {
        console.error('利用可能月データ読み込みエラー:', error)
        const now = new Date()
        currentYear.value = now.getFullYear()
        currentMonth.value = now.getMonth() + 1
      }
    }

    const loadMonthData = async () => {
      if (isLoading.value) return

      const cacheKey = `${currentYear.value}-${currentMonth.value}`

      if (dataCache.has(cacheKey)) {
        const cachedData = dataCache.get(cacheKey)
        Object.assign(statsData, cachedData.stats)
        allTransactions.value = cachedData.transactions
        applyFilters()
        updateCharts()
        return
      }

      isLoading.value = true
      try {
        const monthlyData = await apiService.getMonthlyData(currentYear.value, currentMonth.value)

        statsData.totalAmount = monthlyData.total_amount || 0
        statsData.transactionCount = monthlyData.transaction_count || 0
        statsData.averageDaily = monthlyData.total_amount
          ? Math.round(monthlyData.total_amount / new Date(currentYear.value, currentMonth.value, 0).getDate())
          : 0

        const transactionData = await apiService.getTransactions({
          month: `${currentYear.value}-${currentMonth.value.toString().padStart(2, '0')}`
        })

        const categoryClassMap = {
          '投資': 'investment', '食費': 'food', '日用品費': 'daily',
          '娯楽費': 'entertainment', '住宅費': 'housing', '交通費': 'transport', 'その他': 'other'
        }

        allTransactions.value = transactionData.transactions.map(t => ({
          date: new Date(t.transaction_date).toLocaleDateString('ja-JP'),
          rawDate: t.transaction_date,
          store: t.store_name,
          category: categoryClassMap[t.category?.name || 'その他'] || 'other',
          categoryText: t.category?.name || 'その他',
          amount: formatCurrency(t.amount),
          id: t.id
        }))

        applyFilters()

        if (transactions.value.length > 0) {
          const amounts = transactions.value.map(t => parseFloat(t.amount.replace(/[^\d]/g, '')))
          statsData.maxAmount = Math.max(...amounts)
        }

        updateCharts()

        dataCache.set(cacheKey, {
          stats: { ...statsData },
          transactions: [...allTransactions.value]
        })

        if (dataCache.size > 10) {
          dataCache.delete(dataCache.keys().next().value)
        }

      } catch (error) {
        console.error('月次データ読み込みエラー:', error)
        allTransactions.value = []
        Object.assign(statsData, { totalAmount: 0, maxAmount: 0, averageDaily: 0, transactionCount: 0 })
      } finally {
        isLoading.value = false
      }
    }

    const formatCurrency = (amount) => '￥' + Math.round(amount).toLocaleString()

    // Chart.jsのデフォルト凡例では金額を表示できないため独自実装
    const generateCustomLegend = (categoryData) => {
      const legendContainer = chartLegend.value
      if (!legendContainer) return

      legendContainer.innerHTML = ''

      categoryData.forEach(item => {
        const legendItem = document.createElement('div')
        legendItem.className = 'legend-item'
        legendItem.style.cssText = 'display:flex; flex-direction:row; align-items:center;'

        const colorBox = document.createElement('div')
        colorBox.className = 'legend-color'
        colorBox.style.backgroundColor = item.color || '#999999'

        const textContainer = document.createElement('div')
        textContainer.className = 'legend-text-container'

        const labelText = document.createElement('span')
        labelText.className = 'legend-label'
        labelText.textContent = item.category

        const valueText = document.createElement('span')
        valueText.className = 'legend-value'
        valueText.textContent = props.isPrivacyMode ? '¥*******' : '¥' + Math.round(item.total).toLocaleString()

        textContainer.appendChild(labelText)
        textContainer.appendChild(valueText)
        legendItem.appendChild(colorBox)
        legendItem.appendChild(textContainer)
        legendContainer.appendChild(legendItem)
      })
    }

    const updateCharts = async () => {
      try {
        const monthlyData = await apiService.getMonthlyData(currentYear.value, currentMonth.value)
        const categoryData = monthlyData.category_totals || []

        const allCategories = [
          { category: '投資', color: '#FF6384' },
          { category: '食費', color: '#4BC0C0' },
          { category: '日用品費', color: '#9966FF' },
          { category: '娯楽費', color: '#36A2EB' },
          { category: '住宅費', color: '#FF9F40' },
          { category: '交通費', color: '#FFCE56' },
          { category: 'その他', color: '#C9CBCF' }
        ]

        const completeData = allCategories.map(defaultCat => {
          const foundData = categoryData.find(apiCat => apiCat.category === defaultCat.category)
          return foundData || { ...defaultCat, total: 0 }
        })

        if (categoryChartInstance.value) {
          categoryChartInstance.value.destroy()
          categoryChartInstance.value = null
        }

        if (completeData.length > 0 && categoryPieChart.value) {
          categoryChartInstance.value = new Chart(categoryPieChart.value.getContext('2d'), {
            type: 'doughnut',
            data: {
              labels: completeData.map(cat => cat.category),
              datasets: [{
                data: completeData.map(cat => cat.total),
                backgroundColor: completeData.map(cat => cat.color),
                borderWidth: 2,
                borderColor: '#fff'
              }]
            },
            options: {
              responsive: true,
              maintainAspectRatio: false,
              plugins: {
                legend: { display: false },
                tooltip: {
                  callbacks: {
                    label: (context) => props.isPrivacyMode
                      ? context.label + ': ¥*******'
                      : context.label + ': ¥' + context.parsed.toLocaleString()
                  }
                }
              }
            }
          })
          generateCustomLegend(completeData)
        }

        const mm = currentMonth.value.toString().padStart(2, '0')
        const lastDay = new Date(currentYear.value, currentMonth.value, 0).getDate()
        const analyticsData = await apiService.getAnalyticsData(
          `${currentYear.value}-${mm}-01`,
          `${currentYear.value}-${mm}-${lastDay}`
        )

        const dailyData = analyticsData.daily_totals || {}
        const sortedDates = Object.keys(dailyData).sort()
        const dailyLabels = sortedDates.map(date => {
          const d = new Date(date)
          return `${d.getMonth() + 1}/${d.getDate()}`
        })
        const dailyAmounts = sortedDates.map(date => dailyData[date] || 0)

        if (dailyChartInstance.value) {
          dailyChartInstance.value.destroy()
          dailyChartInstance.value = null
        }

        if (sortedDates.length > 0 && dailyLineChart.value) {
          dailyChartInstance.value = new Chart(dailyLineChart.value.getContext('2d'), {
            type: 'line',
            data: {
              labels: dailyLabels,
              datasets: [{
                label: '支出額',
                data: dailyAmounts,
                borderColor: '#38bdf8',
                backgroundColor: 'rgba(56, 189, 248, 0.1)',
                tension: 0.4,
                fill: true,
                pointBackgroundColor: '#38bdf8',
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
                    callback: (value) => props.isPrivacyMode
                      ? '¥*******'
                      : ('¥' + value.toLocaleString()).padStart(8, ' '),
                    minWidth: 100,
                    padding: 10
                  },
                  afterFit: (scale) => { scale.width = 100 }
                }
              },
              plugins: {
                legend: { display: false },
                tooltip: {
                  callbacks: {
                    label: (context) => props.isPrivacyMode
                      ? '支出額: ¥*******'
                      : '支出額: ¥' + context.parsed.y.toLocaleString()
                  }
                }
              }
            }
          })
        }
      } catch (error) {
        console.error('チャート更新エラー:', error)
      }
    }

    onMounted(() => { loadAvailableMonths() })

    onBeforeUnmount(() => {
      categoryChartInstance.value?.destroy()
      dailyChartInstance.value?.destroy()
    })
    
    return {
      categoryPieChart,
      dailyLineChart,
      chartLegend,
      transactions,
      currentYear,
      currentMonth,
      selectedYear,
      showMonthPicker,
      statsData,
      initialDataLoaded,
      isLoading,
      isNavigating,
      formattedCurrentMonth,
      canGoPrevious,
      canGoNext,
      canGoNextYear,
      canGoPreviousYear,
      hasDataForMonth,
      previousMonth,
      nextMonth,
      previousYear,
      nextYear,
      toggleMonthPicker,
      selectMonth,
      formatCurrency,
      handleCategoryChange,
      updateCharts,
      selectedCategory,
      sortOrder,
      applyFilters,
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
  
  // モバイル対応
  @media (max-width: 480px) {
    gap: 10px;
    
    .month-selector {
      min-width: 110px;
      font-size: 0.9em;
    }
  }
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
  
  svg {
    fill: currentColor;
    transition: all 0.3s ease;
  }
  
  .arrow {
    font-size: 1.2em;
    font-weight: bold;
  }
  
  .arrow-double {
    font-size: 1.0em;
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
    display: flex;
    align-items: center;
    
    svg {
      fill: currentColor;
      transition: transform 0.3s ease;
    }
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

.year-nav-header {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 15px;
  margin-bottom: 15px;
}

.year-display {
  font-size: 1.1em;
  font-weight: 600;
  color: #333;
  min-width: 80px;
  text-align: center;
}

.year-btn {
  background: #f8f9fa;
  border: 1px solid #dee2e6;
  border-radius: 50%;
  width: 30px;
  height: 30px;
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
  
  svg {
    fill: currentColor;
    transition: all 0.3s ease;
  }
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
    opacity: 0.3;
    cursor: not-allowed;
    background: #f8f9fa;
    color: #999;
    border-color: #e9ecef;
    
    &:hover {
      background: #f8f9fa !important;
      cursor: not-allowed !important;
    }
  }
}

.analytics-page {
  
}

.stats-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 20px;
  margin-bottom: 30px;
  
  // モバイル対応
  @media (max-width: 768px) {
    grid-template-columns: repeat(2, 1fr); // 2列固定
    gap: 15px;
  }
  
  @media (max-width: 480px) {
    grid-template-columns: 1fr; // 1列レイアウト
    gap: 15px;
  }
}

.stat-card {
  background: linear-gradient(135deg, #7dd3fc 0%, #38bdf8 100%);
  color: white;
  padding: 20px;
  border-radius: 10px;
  text-align: center;
  
  &.red {
    background: linear-gradient(135deg, #7dd3fc 0%, #38bdf8 100%);
  }
  
  &.green {
    background: linear-gradient(135deg, #7dd3fc 0%, #38bdf8 100%);
  }
  
  &.orange {
    background: linear-gradient(135deg, #7dd3fc 0%, #38bdf8 100%);
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
  
  // モバイル対応
  @media (max-width: 768px) {
    grid-template-columns: 1fr; // 1列レイアウト
    gap: 20px;
  }
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
  
  .pie-chart-wrapper {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 20px;
    align-items: center;
    height: 100%;
    
    canvas {
      max-width: 200px;
      max-height: 200px;
      margin: 0 auto;
    }
    
    .chart-legend {
      .legend-item {
        display: flex;
        align-items: center;
        margin-bottom: 8px;
        padding: 6px 8px;
        background: #f8f9fa;
        border-radius: 6px;
        transition: background 0.2s ease;
        line-height: 1;
        
        &:hover {
          background: #e9ecef;
        }
        
        .legend-color {
          width: 14px;
          height: 14px;
          border-radius: 3px;
          margin-right: 8px;
          flex-shrink: 0;
          display: inline-block;
          vertical-align: middle;
        }
        
        .legend-text-container {
          flex: 1;
          display: inline-flex;
          justify-content: space-between;
          align-items: center;
          vertical-align: middle;
        }
        
        .legend-label {
          font-weight: 500;
          color: #333;
          font-size: 13px;
        }
        
        .legend-value {
          font-weight: 600;
          color: #666;
          font-size: 12px;
          margin-left: 8px;
        }
      }
    }
    
    // モバイル対応
    @media (max-width: 768px) {
      .pie-chart-wrapper {
        grid-template-columns: 1fr;
        gap: 15px;
        
        canvas {
          max-width: 220px;
          max-height: 220px;
        }
        
        .chart-legend {
          .legend-item {
            margin-bottom: 6px;
            padding: 5px 6px;
            
            .legend-text-container {
              .legend-label {
                font-size: 12px;
              }
              
              .legend-value {
                font-size: 11px;
              }
            }
          }
        }
      }
    }
  }
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
  
  // モバイル対応
  @media (max-width: 768px) {
    gap: 10px;
    
    .filter-select {
      flex: 1;
      min-width: 120px;
    }
  }
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
  table-layout: fixed; // 固定レイアウトを強制
}

.table-container {
  overflow: visible;
  position: relative;
  
  // モバイル対応
  @media (max-width: 768px) {
    overflow-x: auto; // 横スクロール有効
    
    .transaction-table {
      min-width: 600px; // 最小幅設定
      
      th, td {
        padding: 8px; // パディング調整
        font-size: 0.85em; // フォントサイズ調整
      }
    }
  }
}

.transaction-table th {
  background: #f8f9fa;
  padding: 12px;
  text-align: left;
  border-bottom: 2px solid #dee2e6;
  font-weight: 600;
  
  // 列幅を固定
  &:nth-child(1) { width: 100px; } // 日付
  &:nth-child(2) { width: 200px; } // 店舗・サービス
  &:nth-child(3) { width: 120px; } // カテゴリ
  &:nth-child(4) { width: 100px; } // 金額
}

.transaction-table td {
  padding: 10px 12px;
  border-bottom: 1px solid #dee2e6;
  
  // セル幅を固定（thと同じ）
  &:nth-child(1) { width: 100px; } // 日付
  &:nth-child(2) { 
    width: 200px; // 店舗・サービス
    max-width: 200px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  &:nth-child(3) { width: 120px; } // カテゴリ
  &:nth-child(4) { width: 100px; } // 金額
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

.privacy-toggle {
  text-align: center;
  margin-bottom: 20px;
}

</style>