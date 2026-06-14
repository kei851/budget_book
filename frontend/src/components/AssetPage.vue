<template lang="pug">
.asset-page
  .month-navigation
    .nav-controls
      button.nav-btn(@click="previousMonth")
        svg(viewBox="0 0 24 24" width="16" height="16")
          path(d="M15 18l-6-6 6-6v12z")
      .month-label {{ formattedMonth }}
      button.nav-btn(@click="nextMonth" :disabled="isCurrentMonth")
        svg(viewBox="0 0 24 24" width="16" height="16")
          path(d="M9 18l6-6-6-6v12z")

  .total-card
    .total-label 総資産
    .total-value {{ isPrivacyMode ? '¥***' : formatCurrency(totalAmount) }}
    .total-diff(v-if="monthlyDiff !== null" :class="monthlyDiff >= 0 ? 'positive' : 'negative'")
      | {{ monthlyDiff >= 0 ? '+' : '' }}{{ isPrivacyMode ? '¥***' : formatCurrency(monthlyDiff) }}（前月比）

  .account-groups
    .account-group(v-for="group in accountGroups" :key="group.type")
      .group-title {{ group.label }}
      .account-rows
        .account-row(v-for="account in group.accounts" :key="account.account_id")
          .account-name {{ account.name }}
          .account-amount {{ isPrivacyMode ? '¥***' : formatCurrency(account.amount) }}

  .chart-section
    .chart-title 総資産推移
    .chart-container
      canvas(ref="historyChart")

  .input-section
    button.input-toggle(@click="showInput = !showInput" v-if="!showInput")
      | {{ hasRecordedThisMonth ? '今月の残高を編集' : '今月の残高を入力' }}

    .input-form(v-if="showInput")
      .form-title {{ formattedMonth }}の残高を入力
      .form-rows
        .form-row(v-for="account in accounts" :key="account.account_id")
          label.form-label {{ account.name }}
          .form-input-wrapper
            span.form-prefix ¥
            input.form-input(
              type="number"
              v-model.number="inputValues[account.account_id]"
              placeholder="0"
              min="0"
            )
      .form-actions
        button.btn-cancel(@click="showInput = false") キャンセル
        button.btn-save(@click="saveSnapshot" :disabled="isSaving")
          | {{ isSaving ? '保存中...' : '保存' }}
</template>

<script>
import { ref, computed, onMounted, watch } from 'vue'
import { Chart, registerables } from 'chart.js'

Chart.register(...registerables)

const API_BASE_URL = 'http://localhost:3001/api/v1'

const TYPE_LABELS = {
  bank: '銀行',
  investment: '投資',
  cash: '現金',
  emoney: '電子マネー'
}
const TYPE_ORDER = ['bank', 'investment', 'cash', 'emoney']

export default {
  name: 'AssetPage',
  props: {
    isPrivacyMode: { type: Boolean, default: false }
  },
  setup() {
    const year = ref(new Date().getFullYear())
    const month = ref(new Date().getMonth() + 1)
    const accounts = ref([])
    const history = ref([])
    const showInput = ref(false)
    const inputValues = ref({})
    const isSaving = ref(false)
    const historyChart = ref(null)
    let chartInstance = null

    const formattedMonth = computed(() => `${year.value}年${month.value}月`)

    const isCurrentMonth = computed(() => {
      const now = new Date()
      return year.value === now.getFullYear() && month.value === now.getMonth() + 1
    })

    const monthKey = computed(() =>
      `${year.value}-${month.value.toString().padStart(2, '0')}`
    )

    const totalAmount = computed(() => accounts.value.reduce((s, a) => s + (a.amount || 0), 0))

    const hasRecordedThisMonth = computed(() => accounts.value.some(a => a.recorded))

    const monthlyDiff = computed(() => {
      if (history.value.length < 2) return null
      const current = history.value.find(h => h.month === monthKey.value)
      if (!current) return null
      const idx = history.value.indexOf(current)
      if (idx === 0) return null
      const prev = history.value[idx - 1]
      return current.total - prev.total
    })

    const accountGroups = computed(() => {
      return TYPE_ORDER
        .map(type => ({
          type,
          label: TYPE_LABELS[type],
          accounts: accounts.value.filter(a => a.account_type === type)
        }))
        .filter(g => g.accounts.length > 0)
    })

    const formatCurrency = (amount) => '¥' + Math.round(amount).toLocaleString()

    const loadAccounts = async () => {
      const res = await fetch(`${API_BASE_URL}/asset_snapshots?month=${monthKey.value}`)
      accounts.value = await res.json()
      inputValues.value = Object.fromEntries(accounts.value.map(a => [a.account_id, a.amount]))
    }

    const loadHistory = async () => {
      const res = await fetch(`${API_BASE_URL}/asset_snapshots/history`)
      history.value = await res.json()
      updateChart()
    }

    const updateChart = () => {
      if (chartInstance) { chartInstance.destroy(); chartInstance = null }
      if (!historyChart.value || history.value.length === 0) return

      chartInstance = new Chart(historyChart.value.getContext('2d'), {
        type: 'line',
        data: {
          labels: history.value.map(h => h.month),
          datasets: [{
            label: '総資産',
            data: history.value.map(h => h.total),
            borderColor: '#6366f1',
            backgroundColor: 'rgba(99, 102, 241, 0.1)',
            tension: 0.4,
            fill: true,
            pointBackgroundColor: '#6366f1',
            pointBorderColor: '#fff',
            pointBorderWidth: 2
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          scales: {
            y: {
              beginAtZero: false,
              ticks: {
                callback: (v) => '¥' + (v / 10000).toFixed(0) + '万'
              }
            }
          },
          plugins: {
            legend: { display: false },
            tooltip: {
              callbacks: {
                label: (ctx) => '総資産: ¥' + ctx.parsed.y.toLocaleString()
              }
            }
          }
        }
      })
    }

    const saveSnapshot = async () => {
      isSaving.value = true
      try {
        const entries = Object.entries(inputValues.value).map(([account_id, amount]) => ({
          account_id: parseInt(account_id),
          amount: amount || 0
        }))
        await fetch(`${API_BASE_URL}/asset_snapshots/bulk_update`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ month: monthKey.value, entries })
        })
        showInput.value = false
        await Promise.all([loadAccounts(), loadHistory()])
      } finally {
        isSaving.value = false
      }
    }

    const previousMonth = () => {
      if (month.value === 1) { month.value = 12; year.value-- }
      else { month.value-- }
    }

    const nextMonth = () => {
      if (isCurrentMonth.value) return
      if (month.value === 12) { month.value = 1; year.value++ }
      else { month.value++ }
    }

    watch(monthKey, () => { loadAccounts(); showInput.value = false })

    onMounted(() => { loadAccounts(); loadHistory() })

    return {
      year, month, accounts, history, showInput, inputValues, isSaving,
      historyChart, formattedMonth, isCurrentMonth, totalAmount,
      hasRecordedThisMonth, monthlyDiff, accountGroups,
      formatCurrency, saveSnapshot, previousMonth, nextMonth
    }
  }
}
</script>

<style lang="scss" scoped>
.asset-page {
  display: flex;
  flex-direction: column;
  gap: $sp-6;
}

.month-navigation {
  background: $color-surface;
  border-radius: $radius-md;
  padding: $sp-5;
  box-shadow: $shadow-sm;
  border: 1px solid $color-border-light;
}

.nav-controls {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: $sp-5;
}

.nav-btn {
  background: $color-surface-sub;
  border: 1px solid $color-border;
  border-radius: 50%;
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: $transition-base;
  color: $color-text-secondary;

  &:hover:not(:disabled) { background: $color-accent; color: #fff; border-color: $color-accent; }
  &:disabled { opacity: 0.3; cursor: not-allowed; }
  svg { fill: currentColor; }
}

.month-label {
  font-size: $font-size-md;
  font-weight: $font-weight-semibold;
  min-width: 120px;
  text-align: center;
}

.total-card {
  background: linear-gradient(135deg, $color-accent 0%, #7c3aed 100%);
  border-radius: $radius-md;
  padding: $sp-8;
  text-align: center;
  color: #fff;
}

.total-label {
  font-size: $font-size-sm;
  opacity: 0.8;
  margin-bottom: $sp-2;
}

.total-value {
  font-size: 2rem;
  font-weight: $font-weight-bold;
  margin-bottom: $sp-2;
}

.total-diff {
  font-size: $font-size-sm;
  opacity: 0.9;

  &.positive { color: #a7f3d0; }
  &.negative { color: #fca5a5; }
}

.account-groups {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: $sp-4;
}

.account-group {
  background: $color-surface;
  border-radius: $radius-md;
  padding: $sp-5;
  box-shadow: $shadow-sm;
  border: 1px solid $color-border-light;
}

.group-title {
  font-size: $font-size-sm;
  font-weight: $font-weight-semibold;
  color: $color-text-secondary;
  margin-bottom: $sp-3;
  padding-bottom: $sp-2;
  border-bottom: 1px solid $color-border-light;
}

.account-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: $sp-2 0;

  & + & { border-top: 1px solid $color-border-light; }
}

.account-name {
  font-size: $font-size-sm;
  color: $color-text-primary;
}

.account-amount {
  font-size: $font-size-sm;
  font-weight: $font-weight-semibold;
  color: $color-text-primary;
}

.chart-section {
  background: $color-surface;
  border-radius: $radius-md;
  padding: $sp-6;
  box-shadow: $shadow-sm;
  border: 1px solid $color-border-light;
}

.chart-title {
  font-size: $font-size-md;
  font-weight: $font-weight-semibold;
  margin-bottom: $sp-5;
  padding-bottom: $sp-2;
  border-bottom: 2px solid $color-border-light;
}

.chart-container {
  height: 240px;
  position: relative;
}

.input-section {
  background: $color-surface;
  border-radius: $radius-md;
  padding: $sp-5;
  box-shadow: $shadow-sm;
  border: 1px solid $color-border-light;
}

.input-toggle {
  width: 100%;
  padding: $sp-3;
  border: 2px dashed $color-border;
  border-radius: $radius-md;
  background: transparent;
  color: $color-accent;
  font-size: $font-size-base;
  font-weight: $font-weight-medium;
  cursor: pointer;
  transition: $transition-fast;

  &:hover { border-color: $color-accent; background: $color-accent-light; }
}

.form-title {
  font-size: $font-size-md;
  font-weight: $font-weight-semibold;
  margin-bottom: $sp-4;
}

.form-rows {
  display: flex;
  flex-direction: column;
  gap: $sp-3;
  margin-bottom: $sp-5;
}

.form-row {
  display: flex;
  align-items: center;
  gap: $sp-4;
}

.form-label {
  width: 120px;
  font-size: $font-size-sm;
  color: $color-text-secondary;
  flex-shrink: 0;
}

.form-input-wrapper {
  display: flex;
  align-items: center;
  gap: $sp-1;
  border: 1px solid $color-border;
  border-radius: $radius-sm;
  padding: $sp-2 $sp-3;
  background: $color-surface-sub;
  flex: 1;

  &:focus-within { border-color: $color-accent; box-shadow: 0 0 0 2px $color-accent-light; }
}

.form-prefix {
  color: $color-text-muted;
  font-size: $font-size-sm;
}

.form-input {
  flex: 1;
  border: none;
  background: transparent;
  font-size: $font-size-sm;
  color: $color-text-primary;
  outline: none;

  &::-webkit-outer-spin-button,
  &::-webkit-inner-spin-button { -webkit-appearance: none; }
}

.form-actions {
  display: flex;
  gap: $sp-3;
  justify-content: flex-end;
}

.btn-cancel {
  padding: $sp-2 $sp-5;
  border: 1px solid $color-border;
  border-radius: $radius-sm;
  background: $color-surface;
  color: $color-text-secondary;
  font-size: $font-size-sm;
  cursor: pointer;
  transition: $transition-fast;

  &:hover { background: $color-surface-sub; }
}

.btn-save {
  padding: $sp-2 $sp-5;
  border: none;
  border-radius: $radius-sm;
  background: $color-accent;
  color: #fff;
  font-size: $font-size-sm;
  font-weight: $font-weight-medium;
  cursor: pointer;
  transition: $transition-fast;

  &:hover:not(:disabled) { background: $color-accent-hover; }
  &:disabled { opacity: 0.5; cursor: not-allowed; }
}
</style>
