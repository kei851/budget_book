<template lang="pug">
.analytics-page
  .month-navigation
    .nav-controls
      button.nav-btn(@click="previousMonth" :disabled="!canGoPrevious || isLoading")
        svg(viewBox="0 0 24 24" width="16" height="16")
          path(d="M15 18l-6-6 6-6v12z")
      .month-selector(@click="toggleMonthPicker" :class="{ loading: isLoading }")
        span.selected-month {{ formattedCurrentMonth }}
        span.loading-indicator(v-if="isLoading") 読み込み中...
        span.dropdown-arrow(v-else)
          svg(viewBox="0 0 24 24" width="14" height="14")
            path(d="M7 14l5-5 5 5z" v-if="showMonthPicker")
            path(d="M7 10l5 5 5-5z" v-else)
      button.nav-btn(@click="nextMonth" :disabled="!canGoNext || isLoading")
        svg(viewBox="0 0 24 24" width="16" height="16")
          path(d="M9 18l6-6-6-6v12z")
    
    .month-picker(v-show="showMonthPicker")
      .year-nav-header
        button.year-btn(@click="previousYear" :disabled="!canGoPreviousYear || isLoading")
          svg(viewBox="0 0 24 24" width="18" height="18")
            path(d="M18 17l-6-5 6-5v10zM12 17l-6-5 6-5v10z")
        .year-display {{ currentYear }}年
        button.year-btn(@click="nextYear" :disabled="!canGoNextYear || isLoading")
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
  
  .privacy-toggle
    button.privacy-btn(@click="togglePrivacyMode" :class="{ active: isPrivacyMode }")
      span.privacy-icon 👁
      span.privacy-text {{ isPrivacyMode ? '金額表示' : '金額非表示' }}
  
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
  components: {
    CategoryTag
  },
  setup() {
    const categoryPieChart = ref(null) // canvas要素
    const dailyLineChart = ref(null)   // canvas要素
    const categoryChartInstance = ref(null) // chart instance
    const dailyChartInstance = ref(null)    // chart instance
    
    // 月選択の状態
    const currentYear = ref(new Date().getFullYear())
    const currentMonth = ref(new Date().getMonth() + 1)
    const selectedYear = ref(new Date().getFullYear())
    const showMonthPicker = ref(false)
    const availableMonths = ref([]) // データがある月の配列
    const initialDataLoaded = ref(false)
    const isLoading = ref(false) // データ読み込み中フラグ
    const isPrivacyMode = ref(false) // 金額非表示モード
    const dataCache = new Map() // データキャッシュ
    
    // 統計データ
    const statsData = reactive({
      totalAmount: 0,
      maxAmount: 0,
      averageDaily: 0,
      transactionCount: 0
    })
    
    // 実際のデータ
    const transactions = ref([])
    const allTransactions = ref([]) // フィルタリング前の全データ
    
    // フィルタリング・ソート関連
    const selectedCategory = ref('')
    const sortOrder = ref('date_desc')
    
    // フィルタリング・ソート機能
    const applyFilters = () => {
      let filtered = [...allTransactions.value]
      
      // カテゴリフィルタリング
      if (selectedCategory.value) {
        filtered = filtered.filter(t => t.categoryText === selectedCategory.value)
      }
      
      // ソート
      filtered.sort((a, b) => {
        switch (sortOrder.value) {
          case 'amount_desc':
            return parseFloat(b.amount.replace(/[^\d]/g, '')) - parseFloat(a.amount.replace(/[^\d]/g, ''))
          case 'amount_asc':
            return parseFloat(a.amount.replace(/[^\d]/g, '')) - parseFloat(b.amount.replace(/[^\d]/g, ''))
          case 'date_desc':
            return new Date(b.rawDate) - new Date(a.rawDate)
          case 'date_asc':
            return new Date(a.rawDate) - new Date(b.rawDate)
          default:
            return 0
        }
      })
      
      transactions.value = filtered
    }
    
    const handleCategoryChange = async (index, newCategory) => {
      try {
        const transaction = transactions.value[index]
        
        // APIを呼び出してカテゴリを更新
        const result = await apiService.updateTransaction(transaction.id, {
          category_name: newCategory.text
        })
        
        console.log('カテゴリ更新成功:', result)
        
        // ローカルデータを更新（カテゴリクラス名も適切に設定）
        const getCategoryClass = (categoryName) => {
          const mapping = {
            '投資': 'investment',
            '食費': 'food', 
            '日用品費': 'daily',
            '娯楽費': 'entertainment',
            '住宅費': 'housing',
            '交通費': 'transport',
            'その他': 'other'
          }
          return mapping[categoryName] || 'other'
        }
        
        transactions.value[index].category = getCategoryClass(newCategory.text)
        transactions.value[index].categoryText = newCategory.text
        
        // チャートとサマリーを再更新
        await loadMonthData()
        
      } catch (error) {
        console.error('カテゴリ更新エラー:', error)
        alert('カテゴリの更新に失敗しました: ' + error.message)
      }
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
    
    const canGoNextYear = computed(() => {
      const now = new Date()
      return currentYear.value < now.getFullYear()
    })
    
    const canGoPreviousYear = computed(() => {
      // 最も古いデータの年まで戻れるかチェック
      if (availableMonths.value.length === 0) return false
      
      const oldestMonth = availableMonths.value[0] // ソート済み前提
      const oldestYear = parseInt(oldestMonth.split('-')[0])
      return currentYear.value > oldestYear
    })
    
    const hasDataForMonth = (month) => {
      // 年選択ピッカーで表示されている年を使用
      const yearToCheck = currentYear.value
      const monthKey = `${yearToCheck}-${month.toString().padStart(2, '0')}`
      const hasData = availableMonths.value.includes(monthKey)
      
      
      return hasData
    }
    
    const previousMonth = async () => {
      if (isLoading.value) return // 読み込み中の場合は処理しない
      
      if (currentMonth.value === 1) {
        currentMonth.value = 12
        currentYear.value--
      } else {
        currentMonth.value--
      }
      await loadMonthData()
    }
    
    const nextMonth = async () => {
      if (isLoading.value) return // 読み込み中の場合は処理しない
      
      if (currentMonth.value === 12) {
        currentMonth.value = 1
        currentYear.value++
      } else {
        currentMonth.value++
      }
      await loadMonthData()
    }
    
    const toggleMonthPicker = () => {
      console.log('Toggle month picker clicked', showMonthPicker.value)
      showMonthPicker.value = !showMonthPicker.value
    }

    const selectMonth = async (month) => {
      if (isLoading.value) return // 読み込み中の場合は処理しない
      
      // 重複リクエスト防止のためにさらに厳密にチェック
      if (currentMonth.value === month) {
        showMonthPicker.value = false
        return
      }
      
      currentMonth.value = month
      showMonthPicker.value = false
      
      try {
        await loadMonthData()
      } catch (error) {
        console.error('月選択エラー:', error)
      }
    }
    
    const previousYear = async () => {
      if (isLoading.value) return // 読み込み中の場合は処理しない
      
      currentYear.value--
      await loadMonthData()
    }
    
    const nextYear = async () => {
      if (isLoading.value) return // 読み込み中の場合は処理しない
      
      if (canGoNextYear.value) {
        currentYear.value++
        await loadMonthData()
      }
    }
    
    // 利用可能な月データを読み込み
    const loadAvailableMonths = async () => {
      try {
        // 実際のトランザクションデータから利用可能月を取得
        const transactionData = await apiService.getTransactions()
        if (transactionData.transactions && transactionData.transactions.length > 0) {
          // 全トランザクションから年月を抽出
          const monthSet = new Set()
          transactionData.transactions.forEach(transaction => {
            const date = new Date(transaction.transaction_date)
            const monthKey = `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}`
            monthSet.add(monthKey)
          })
          
          // 利用可能な月をソート
          availableMonths.value = Array.from(monthSet).sort()
          
          // 最新の取引日付を取得
          const sortedTransactions = transactionData.transactions.sort((a, b) => 
            new Date(b.transaction_date) - new Date(a.transaction_date)
          )
          const latestDate = new Date(sortedTransactions[0].transaction_date)
          
          currentYear.value = latestDate.getFullYear()
          currentMonth.value = latestDate.getMonth() + 1
          initialDataLoaded.value = true
          
          console.log(`初期表示: ${currentYear.value}年${currentMonth.value}月`)
          
          // データを読み込み
          await loadMonthData()
        } else {
          // データがない場合は現在日付
          const now = new Date()
          currentYear.value = now.getFullYear()
          currentMonth.value = now.getMonth() + 1
          initialDataLoaded.value = true
        }
      } catch (error) {
        console.error('利用可能月データ読み込みエラー:', error)
        // エラーの場合は現在日付
        const now = new Date()
        currentYear.value = now.getFullYear()
        currentMonth.value = now.getMonth() + 1
      }
    }
    
    // 月次データ読み込み
    const loadMonthData = async () => {
      if (isLoading.value) return // 既に読み込み中の場合は処理しない
      
      // キャッシュキーを生成
      const cacheKey = `${currentYear.value}-${currentMonth.value}`
      
      // キャッシュからデータを取得
      if (dataCache.has(cacheKey)) {
        console.log('キャッシュからデータを取得:', cacheKey)
        const cachedData = dataCache.get(cacheKey)
        
        // キャッシュデータを使用してUI更新
        Object.assign(statsData, cachedData.stats)
        allTransactions.value = cachedData.transactions
        applyFilters()
        updateCharts()
        return
      }
      
      isLoading.value = true
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
        
        // カテゴリ名から適切なクラス名にマッピング
        const getCategoryClass = (categoryName) => {
          const mapping = {
            '投資': 'investment',
            '食費': 'food', 
            '日用品費': 'daily',
            '娯楽費': 'entertainment',
            '住宅費': 'housing',
            '交通費': 'transport',
            'その他': 'other'
          }
          return mapping[categoryName] || 'other'
        }
        
        allTransactions.value = transactionData.transactions.map(t => ({
          date: new Date(t.transaction_date).toLocaleDateString('ja-JP'),
          rawDate: t.transaction_date, // ソート用の生データ
          store: t.store_name,
          category: getCategoryClass(t.category?.name || 'その他'),
          categoryText: t.category?.name || 'その他',
          amount: formatCurrency(t.amount),
          id: t.id
        }))
        
        // フィルタリング・ソートを適用
        applyFilters()
        
        // 最大支出を計算
        if (transactions.value.length > 0) {
          const amounts = transactions.value.map(t => parseFloat(t.amount.replace(/[^\d]/g, '')))
          statsData.maxAmount = Math.max(...amounts)
        }
        
        // チャートを更新
        updateCharts()
        
        // データをキャッシュに保存
        dataCache.set(cacheKey, {
          stats: { ...statsData },
          transactions: [...allTransactions.value]
        })
        
        // キャッシュサイズ制限（最大10件）
        if (dataCache.size > 10) {
          const firstKey = dataCache.keys().next().value
          dataCache.delete(firstKey)
        }
        
      } catch (error) {
        console.error('月次データ読み込みエラー:', error)
        // エラー時もUIを正常状態に戻す
        allTransactions.value = []
        Object.assign(statsData, {
          totalAmount: 0,
          maxAmount: 0,
          averageDaily: 0,
          transactionCount: 0
        })
      } finally {
        isLoading.value = false // 処理完了後に必ずloading状態を解除
      }
    }
    
    
    const formatCurrency = (amount) => {
      return '￥' + Math.round(amount).toLocaleString()
    }
    
    const togglePrivacyMode = () => {
      isPrivacyMode.value = !isPrivacyMode.value
      // プライバシーモード切り替え時にチャートを再描画
      updateCharts()
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
        if (categoryChartInstance.value) {
          categoryChartInstance.value.destroy()
          categoryChartInstance.value = null
        }
        
        if (categoryData.length > 0 && categoryPieChart.value) {
          const ctx1 = categoryPieChart.value.getContext('2d')
          categoryChartInstance.value = new Chart(ctx1, {
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
                  legend: { display: false },
                  tooltip: {
                    callbacks: {
                      label: function(context) {
                        if (isPrivacyMode.value) {
                          return context.label + ': ¥***'
                        } else {
                          return context.label + ': ¥' + context.parsed.toLocaleString()
                        }
                      }
                    }
                  }
                }
              }
            })
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
        if (dailyChartInstance.value) {
          dailyChartInstance.value.destroy()
          dailyChartInstance.value = null
        }
        
        if (sortedDates.length > 0 && dailyLineChart.value) {
          const ctx2 = dailyLineChart.value.getContext('2d')
          dailyChartInstance.value = new Chart(ctx2, {
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
                        return isPrivacyMode.value ? '¥***' : '¥' + value.toLocaleString()
                      }
                    }
                  }
                },
                plugins: {
                  legend: { display: false },
                  tooltip: {
                    callbacks: {
                      label: function(context) {
                        if (isPrivacyMode.value) {
                          return '支出額: ¥***'
                        } else {
                          return '支出額: ¥' + context.parsed.y.toLocaleString()
                        }
                      }
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

    onMounted(() => {
      loadAvailableMonths()
    })
    
    onBeforeUnmount(() => {
      if (categoryChartInstance.value) {
        categoryChartInstance.value.destroy()
      }
      if (dailyChartInstance.value) {
        dailyChartInstance.value.destroy()
      }
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
      isLoading,
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
      isPrivacyMode,
      togglePrivacyMode
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

.privacy-btn {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 25px;
  cursor: pointer;
  transition: all 0.3s ease;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  font-size: 0.9em;
  
  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
  }
  
  &.active {
    background: linear-gradient(135deg, #ff7675 0%, #fd79a8 100%);
    
    .privacy-icon {
      filter: brightness(0.8);
    }
  }
  
  .privacy-icon {
    font-size: 1.1em;
    transition: all 0.3s ease;
  }
  
  .privacy-text {
    font-weight: 600;
  }
}
</style>