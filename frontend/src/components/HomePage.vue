<template lang="pug">
.home-page
  .upload-grid
    .upload-area
      .upload-icon 📁
      p.upload-label 対応形式のCSVファイルをアップロード
      FileUpload(@file-uploaded="handleFileUpload" @folder-uploaded="handleFolderUpload" :loading="loading")

    .format-card
      h3.format-title 対応ファイル形式
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
            td: span.badge.badge-supported ✓ 対応
          tr
            td 楽天銀行
            td CSV
            td: span.badge.badge-planned 予定
          tr
            td エポスカード
            td CSV
            td: span.badge.badge-supported ✓ 対応
          tr
            td PayPay
            td CSV
            td: span.badge.badge-planned 予定

  .chart-card
    .chart-card-header
      h2.section-title 月別支出（12ヶ月）
    ExpenseChart(:data="chartData" :isPrivacyMode="isPrivacyMode" @navigation-state="handleNavigationState")
    SummaryCards(:summary="summaryData" :isPrivacyMode="isPrivacyMode")
</template>

<script>
import { ref, reactive, onMounted } from 'vue'
import FileUpload from './FileUpload.vue'
import ExpenseChart from './ExpenseChart.vue'
import SummaryCards from './SummaryCards.vue'
import apiService from '../services/api.js'

export default {
  name: 'HomePage',
  components: { FileUpload, ExpenseChart, SummaryCards },
  props: {
    isPrivacyMode: { type: Boolean, default: false },
    chartNavigationState: {
      type: Object,
      default: () => ({ canGoPrevious: false, canGoNext: false, totalMonths: 0, currentOffset: 0, availableMonths: [] })
    }
  },
  emits: ['navigate', 'chart-navigation-updated'],
  setup(props, { emit }) {
    const loading = ref(false)
    const chartData = ref({ labels: [], datasets: [] })
    const summaryData = reactive({ thisMonth: 0, monthlyAverage: 0, maxMonth: 0, dataCount: 0 })

    const loadData = async () => {
      try {
        const monthlyData = await apiService.getMonthlyData()
        await updateChartData()
        updateSummaryData(monthlyData)
      } catch (error) {
        console.error('データ読み込みエラー:', error)
        chartData.value = { labels: [], datasets: [] }
      }
    }

    const updateChartData = async () => {
      try {
        const analyticsData = await apiService.getAnalyticsData()
        if (!analyticsData.category_stats?.length) { chartData.value = { labels: [], datasets: [] }; return }

        const allMonths = new Set()
        analyticsData.category_stats.forEach(c => {
          if (c.monthly_data) Object.keys(c.monthly_data).forEach(m => allMonths.add(m))
        })
        const sortedMonths = Array.from(allMonths).sort()

        chartData.value = {
          labels: sortedMonths.map(m => { const [y, mo] = m.split('-'); return `${y}/${mo}` }),
          datasets: analyticsData.category_stats.map(c => ({
            label: c.name,
            data: sortedMonths.map(m => c.monthly_data[m] ? Math.round(parseFloat(c.monthly_data[m])) : 0),
            backgroundColor: c.color,
            borderWidth: 0
          })).filter(d => d.data.some(v => v > 0))
        }
      } catch (error) {
        console.error('チャートデータ更新エラー:', error)
        chartData.value = { labels: [], datasets: [] }
      }
    }

    const updateSummaryData = (data) => {
      const now = new Date()
      const key = `${now.getFullYear()}-${(now.getMonth() + 1).toString().padStart(2, '0')}-01`
      summaryData.thisMonth = data.monthly_totals[key] ? Math.round(parseFloat(data.monthly_totals[key])) : 0
      const vals = Object.values(data.monthly_totals).map(parseFloat).filter(v => !isNaN(v) && v > 0)
      summaryData.monthlyAverage = vals.length ? Math.round(vals.reduce((a, b) => a + b, 0) / vals.length) : 0
      summaryData.maxMonth = vals.length ? Math.round(Math.max(...vals)) : 0
      summaryData.dataCount = data.transaction_count || 0
    }

    const handleFileUpload = async (file) => {
      loading.value = true
      try {
        const result = await apiService.uploadCsv(file, false)
        if (result.imported_count > 0) {
          alert(`${result.imported_count}件のデータをインポートしました！`)
          await loadData()
        } else {
          alert('インポートできるデータが見つかりませんでした。')
        }
      } catch (error) {
        alert(`アップロードに失敗しました: ${error.message}`)
      } finally {
        loading.value = false
      }
    }

    const handleFolderUpload = async ({ files, uploadProgress }) => {
      loading.value = true
      const results = []
      for (let i = 0; i < files.length; i++) {
        uploadProgress.current = i + 1
        try {
          const result = await apiService.uploadCsv(files[i], i === 0)
          results.push({ status: 'success', importedCount: result.imported_count || 0 })
          await new Promise(r => setTimeout(r, 300))
        } catch (error) {
          const alreadyUploaded = error.message?.includes('既にアップロード済み')
          results.push({ status: alreadyUploaded ? 'skipped' : 'error' })
        }
      }
      uploadProgress.current = 0; uploadProgress.total = 0
      loading.value = false

      const success = results.filter(r => r.status === 'success')
      const skipped = results.filter(r => r.status === 'skipped')
      const errors = results.filter(r => r.status === 'error')
      const total = success.reduce((s, r) => s + r.importedCount, 0)
      if (success.length > 0 || skipped.length > 0) {
        const parts = []
        if (success.length > 0) parts.push(`${total}件をインポートしました`)
        if (skipped.length > 0) parts.push(`${skipped.length}個は既にアップロード済みのためスキップ`)
        if (errors.length > 0) parts.push(`${errors.length}個はエラー`)
        alert(parts.join('\n'))
        await loadData()
      } else {
        alert('処理可能なデータが見つかりませんでした。')
      }
    }

    const handleNavigationState = (state) => { emit('chart-navigation-updated', state) }

    onMounted(() => { loadData() })

    return { loading, chartData, summaryData, handleFileUpload, handleFolderUpload, handleNavigationState }
  }
}
</script>

<style lang="scss" scoped>

.home-page { display: flex; flex-direction: column; gap: $sp-6; }

.upload-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: $sp-5;

  @media (max-width: $bp-md) { grid-template-columns: 1fr; }
}

.upload-area {
  border: 2px dashed $color-border;
  border-radius: $radius-lg;
  padding: $sp-8;
  text-align: center;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: $sp-4;
  transition: $transition-base;

  &:hover { border-color: $color-accent; background: $color-accent-light; }
}

.upload-icon { font-size: 2.5rem; }

.upload-label {
  font-size: $font-size-base;
  color: $color-text-secondary;
}

.format-card {
  background: $color-surface;
  border: 1px solid $color-border;
  border-radius: $radius-lg;
  padding: $sp-5;
  box-shadow: $shadow-xs;
}

.format-title {
  font-size: $font-size-md;
  font-weight: $font-weight-semibold;
  color: $color-text-primary;
  margin-bottom: $sp-4;
}

.format-table {
  width: 100%;
  border-collapse: collapse;

  th {
    background: $color-surface-sub;
    padding: $sp-2 $sp-3;
    text-align: left;
    font-size: $font-size-sm;
    font-weight: $font-weight-semibold;
    color: $color-text-secondary;
    border-bottom: 1px solid $color-border;
  }

  td {
    padding: $sp-3;
    font-size: $font-size-sm;
    border-bottom: 1px solid $color-border-light;
    color: $color-text-primary;
  }

  tr:last-child td { border-bottom: none; }
}

.badge {
  display: inline-block;
  padding: 2px $sp-2;
  border-radius: $radius-full;
  font-size: $font-size-xs;
  font-weight: $font-weight-semibold;

  &-supported { background: #d1fae5; color: #065f46; }
  &-planned { background: #fef3c7; color: #92400e; }
}

.chart-card {
  background: $color-surface;
  border: 1px solid $color-border;
  border-radius: $radius-lg;
  padding: $sp-6;
  box-shadow: $shadow-xs;
}

.chart-card-header {
  margin-bottom: $sp-5;
  padding-bottom: $sp-4;
  border-bottom: 1px solid $color-border-light;
}
</style>
