<template lang="pug">
.home-page
  .page-actions
    button.btn-manual-entry(@click="showManualEntry = true")
      span ✏️ 手入力で追加

  ManualEntryModal(
    v-if="showManualEntry"
    @close="showManualEntry = false"
    @saved="loadData"
  )

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
            td: span.badge.badge-supported ✓ 対応
          tr
            td エポスカード
            td CSV
            td: span.badge.badge-supported ✓ 対応
          tr
            td PayPay
            td CSV
            td: span.badge.badge-planned 予定
          tr
            td 楽天証券
            td CSV
            td: span.badge.badge-planned 予定
          tr
            td ゆうちょ銀行
            td CSV
            td: span.badge.badge-planned 予定

  DataCoverageCard

  MonthlyTasksCard

  .chart-card
    .chart-card-header
      h2.section-title 月別支出（12ヶ月）
    ExpenseChart(:data="chartData" :isPrivacyMode="isPrivacyMode" @navigation-state="handleNavigationState")
    SummaryCards(:summary="summaryData" :isPrivacyMode="isPrivacyMode")

  .ai-insights-card
    .ai-insights-header
      .ai-insights-title
        .ai-icon ✨
        span 今月のインサイト
      .ai-insights-actions(v-if="aiInsight")
        button.btn-refresh(@click="loadAiInsight" :disabled="insightLoading")
          svg(viewBox="0 0 24 24" width="14" height="14" fill="currentColor")
            path(d="M17.65 6.35A7.958 7.958 0 0 0 12 4c-4.42 0-7.99 3.58-7.99 8s3.57 8 7.99 8c3.73 0 6.84-2.55 7.73-6h-2.08A5.99 5.99 0 0 1 12 18c-3.31 0-6-2.69-6-6s2.69-6 6-6c1.66 0 3.14.69 4.22 1.78L13 11h7V4l-2.35 2.35z")
          span 更新
    .ai-insights-body
      .ai-loading(v-if="insightLoading")
        .loading-dots
          span
          span
          span
        span.loading-text Claudeが分析中...
      .ai-insight-text(v-else-if="aiInsight") {{ aiInsight }}
      .ai-empty(v-else)
        p.ai-empty-desc 直近の支出トレンドをClaudeが分析します。
        button.btn-generate(@click="loadAiInsight" :disabled="insightLoading")
          span ✨ インサイトを生成
</template>

<script>
import { ref, reactive, onMounted } from 'vue'
import FileUpload from './FileUpload.vue'
import ExpenseChart from './ExpenseChart.vue'
import SummaryCards from './SummaryCards.vue'
import DataCoverageCard from './DataCoverageCard.vue'
import ManualEntryModal from './ManualEntryModal.vue'
import MonthlyTasksCard from './MonthlyTasksCard.vue'
import apiService from '../services/api.js'

const API_BASE_URL = 'http://localhost:3001/api/v1'

export default {
  name: 'HomePage',
  components: { FileUpload, ExpenseChart, SummaryCards, DataCoverageCard, ManualEntryModal, MonthlyTasksCard },
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
    const showManualEntry = ref(false)
    const chartData = ref({ labels: [], datasets: [] })
    const summaryData = reactive({ thisMonth: 0, monthlyAverage: 0, maxMonth: 0, dataCount: 0 })
    const aiInsight = ref(null)
    const insightLoading = ref(false)

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

    const loadAiInsight = async () => {
      if (insightLoading.value) return
      insightLoading.value = true
      aiInsight.value = null
      try {
        const now = new Date()
        const res = await apiService.getAiMonthlySummary(now.getFullYear(), now.getMonth() + 1)
        aiInsight.value = res.summary
      } catch (e) {
        aiInsight.value = 'インサイトの生成に失敗しました。'
      } finally {
        insightLoading.value = false
      }
    }

    onMounted(() => { loadData() })

    return { loading, showManualEntry, chartData, summaryData, aiInsight, insightLoading, handleFileUpload, handleFolderUpload, handleNavigationState, loadAiInsight, loadData }
  }
}
</script>

<style lang="scss" scoped>

.home-page { display: flex; flex-direction: column; gap: $sp-6; }

.page-actions {
  display: flex;
  justify-content: flex-end;
}

.btn-manual-entry {
  display: flex;
  align-items: center;
  gap: $sp-2;
  padding: $sp-2 + 2 $sp-4;
  background: $color-surface;
  border: 1px solid $color-border;
  border-radius: $radius-full;
  font-size: $font-size-sm;
  font-weight: $font-weight-medium;
  color: $color-text-secondary;
  cursor: pointer;
  transition: $transition-fast;
  box-shadow: $shadow-xs;

  &:hover {
    background: $color-accent-light;
    border-color: $color-accent;
    color: $color-accent;
  }
}

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

.ai-insights-card {
  background: linear-gradient(135deg, #f0f7ff 0%, #faf5ff 100%);
  border: 1px solid #c7d9f0;
  border-radius: $radius-lg;
  padding: $sp-6;
  box-shadow: $shadow-xs;
}

.ai-insights-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: $sp-4;
}

.ai-insights-title {
  display: flex;
  align-items: center;
  gap: $sp-2;
  font-size: $font-size-md;
  font-weight: $font-weight-semibold;
  color: $color-text-primary;

  .ai-icon { font-size: 1.1rem; }
}

.btn-refresh {
  display: flex;
  align-items: center;
  gap: $sp-1;
  padding: $sp-1 + 2 $sp-3;
  background: $color-surface;
  border: 1px solid $color-border;
  border-radius: $radius-sm;
  font-size: $font-size-sm;
  color: $color-text-secondary;
  cursor: pointer;
  transition: $transition-fast;

  &:hover:not(:disabled) {
    background: $color-accent-light;
    color: $color-accent;
    border-color: $color-accent;
  }

  &:disabled { opacity: 0.5; cursor: not-allowed; }
}

.ai-loading {
  display: flex;
  align-items: center;
  gap: $sp-3;
  padding: $sp-4 0;
  color: $color-text-secondary;
  font-size: $font-size-sm;
}

.loading-dots {
  display: flex;
  gap: 4px;

  span {
    width: 6px;
    height: 6px;
    background: $color-accent;
    border-radius: 50%;
    animation: dot-bounce 1.2s infinite ease-in-out;

    &:nth-child(1) { animation-delay: 0s; }
    &:nth-child(2) { animation-delay: 0.2s; }
    &:nth-child(3) { animation-delay: 0.4s; }
  }
}

@keyframes dot-bounce {
  0%, 80%, 100% { transform: scale(0.6); opacity: 0.5; }
  40% { transform: scale(1); opacity: 1; }
}

.ai-insight-text {
  font-size: $font-size-base;
  color: $color-text-primary;
  line-height: 1.8;
  white-space: pre-wrap;
}

.ai-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: $sp-4;
  padding: $sp-4 0;

  .ai-empty-desc {
    font-size: $font-size-sm;
    color: $color-text-secondary;
    text-align: center;
    margin: 0;
  }
}

.btn-generate {
  padding: $sp-3 $sp-6;
  background: linear-gradient(135deg, $color-accent 0%, #7c3aed 100%);
  border: none;
  border-radius: $radius-full;
  color: #fff;
  font-size: $font-size-sm;
  font-weight: $font-weight-semibold;
  cursor: pointer;
  transition: $transition-base;
  box-shadow: 0 2px 8px rgba(99, 102, 241, 0.35);

  &:hover:not(:disabled) {
    transform: translateY(-1px);
    box-shadow: 0 4px 12px rgba(99, 102, 241, 0.45);
  }

  &:disabled { opacity: 0.5; cursor: not-allowed; transform: none; }
}
</style>
