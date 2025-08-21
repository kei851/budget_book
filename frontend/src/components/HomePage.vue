<template lang="pug">
.home-page
  .upload-container
    .upload-section
      .upload-icon 📁
      .upload-text 右の対応済みの形式のファイルをアップロード
      FileUpload(
        @file-uploaded="handleFileUpload" 
        @folder-uploaded="handleFolderUpload"
        :loading="loading"
      )
    
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
  
  .privacy-toggle
    button.privacy-btn(@click="togglePrivacyMode" :class="{ active: isPrivacyMode }")
      span.privacy-icon 👁
      span.privacy-text {{ isPrivacyMode ? '金額表示' : '金額非表示' }}

  .chart-section
    .chart-header
      .chart-title 月毎支出グラフ（12ヶ月）
    
    ExpenseChart(
      :data="chartData"
      :isPrivacyMode="isPrivacyMode"
    )
    
    SummaryCards(:summary="summaryData" :isPrivacyMode="isPrivacyMode" @navigate-to-analytics="$emit('navigate', 'analytics')")
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
    const uploadSuccess = ref(false)
    const isPrivacyMode = ref(false) // 金額非表示モード
    
    // リアクティブなデータ
    const chartData = ref({
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
        chartData.value = {
          labels: [],
          datasets: []
        }
      }
    }
    
    // チャートデータ更新
    const updateChartData = async () => {
      try {
        const analyticsData = await apiService.getAnalyticsData()
        
        if (!analyticsData.category_stats || analyticsData.category_stats.length === 0) {
          chartData.value = {
            labels: [],
            datasets: []
          }
          return
        }

        // 全ての月データを取得して過去12ヶ月分を決定
        const allMonths = new Set()
        analyticsData.category_stats.forEach(category => {
          if (category.monthly_data) {
            Object.keys(category.monthly_data).forEach(month => {
              allMonths.add(month)
            })
          }
        })
        
        const sortedMonths = Array.from(allMonths).sort().slice(-12)
        
        // 各カテゴリのデータセットを作成
        const datasets = analyticsData.category_stats.map(category => ({
          label: category.name,
          data: sortedMonths.map(month => {
            const value = category.monthly_data[month]
            return value ? Math.round(parseFloat(value)) : 0
          }),
          backgroundColor: category.color,
          borderWidth: 0
        }))
        
        chartData.value = {
          labels: sortedMonths.map(monthKey => {
            const [year, month] = monthKey.split('-')
            return `${year}/${month}`
          }),
          datasets: datasets.filter(dataset => 
            dataset.data.some(val => val > 0)
          )
        }
        
      } catch (error) {
        console.error('チャートデータ更新エラー:', error)
        chartData.value = {
          labels: [],
          datasets: []
        }
      }
    }
    
    // サマリーデータ更新
    const updateSummaryData = (data) => {
      const currentMonth = new Date().getMonth() + 1
      const currentYear = new Date().getFullYear()
      const currentMonthKey = `${currentYear}-${currentMonth.toString().padStart(2, '0')}-01`
      
      summaryData.thisMonth = data.monthly_totals[currentMonthKey] 
        ? Math.round(parseFloat(data.monthly_totals[currentMonthKey])) : 0
      
      const monthlyValues = Object.values(data.monthly_totals)
        .map(val => parseFloat(val))
        .filter(val => !isNaN(val) && val > 0)
      
      summaryData.monthlyAverage = monthlyValues.length > 0 
        ? Math.round(monthlyValues.reduce((a, b) => a + b, 0) / monthlyValues.length) 
        : 0
      summaryData.maxMonth = monthlyValues.length > 0 ? Math.round(Math.max(...monthlyValues)) : 0
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
    
    const handleFolderUpload = async (data) => {
      console.log('フォルダーアップロード開始:', data.files.length, '個のファイル')
      
      loading.value = true
      const files = data.files
      const uploadProgress = data.uploadProgress
      const results = []
      
      for (let i = 0; i < files.length; i++) {
        const file = files[i]
        uploadProgress.current = i + 1
        
        try {
          console.log(`ファイル ${i + 1}/${files.length} 処理中: ${file.name}`)
          
          // 最初のファイルのみ既存データを削除、残りは追加
          const clearExisting = i === 0
          const result = await apiService.uploadCsv(file, clearExisting)
          console.log(`${file.name} 完了:`, result)
          console.log('result.imported_count:', result.imported_count)
          
          results.push({ 
            file: file.name, 
            status: 'success', 
            importedCount: result.imported_count || 0
          })
          
          // 少し待機
          await new Promise(resolve => setTimeout(resolve, 300))
          
        } catch (error) {
          console.error(`${file.name} の処理でエラー:`, error)
          results.push({ 
            file: file.name, 
            status: 'error', 
            error: error.message 
          })
        }
      }
      
      // 処理完了
      uploadProgress.current = 0
      uploadProgress.total = 0
      loading.value = false
      
      const successCount = results.filter(r => r.status === 'success').length
      const errorCount = results.filter(r => r.status === 'error').length
      const totalImported = results
        .filter(r => r.status === 'success')
        .reduce((sum, r) => sum + r.importedCount, 0)
      
      console.log('フォルダーアップロード完了結果:', {
        成功ファイル数: successCount,
        エラーファイル数: errorCount,
        合計インポート件数: totalImported,
        詳細: results
      })
      
      if (successCount > 0 || totalImported > 0) {
        alert(`${successCount}個のファイルを処理完了！\n合計 ${totalImported}件のデータをインポートしました。${errorCount > 0 ? `\n${errorCount}個のファイルは空またはエラーでした。` : ''}`)
        
        // データを再読み込み
        await loadData()
      } else {
        alert('処理可能なデータが見つかりませんでした。CSVファイルの内容を確認してください。')
      }
    }
    
    
    const togglePrivacyMode = () => {
      isPrivacyMode.value = !isPrivacyMode.value
    }
    
    // 初期データ読み込み
    onMounted(() => {
      loadData()
    })
    
    return {
      loading,
      chartData,
      summaryData,
      uploadSuccess,
      handleFileUpload,
      handleFolderUpload,
      isPrivacyMode,
      togglePrivacyMode
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

.privacy-toggle {
  text-align: center;
  margin: 20px 0;
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