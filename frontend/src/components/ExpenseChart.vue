<template lang="pug">
.expense-chart
  .chart-nav
    button.nav-btn(:disabled="!canGoPrevious || isUpdating" @click="shiftChart(-1)") ←
    span.chart-period {{ chartPeriodText }}
    button.nav-btn(:disabled="!canGoNext || isUpdating" @click="shiftChart(1)") →
  .chart-wrap
    canvas(ref="chartCanvas")
</template>

<script>
import { ref, onMounted, onBeforeUnmount, watch, nextTick } from 'vue'
import { Chart, CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend } from 'chart.js'

Chart.register(CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend)

export default {
  name: 'ExpenseChart',
  props: {
    data: { type: Object, required: true },
    isPrivacyMode: { type: Boolean, default: false }
  },
  emits: ['navigation-state'],
  setup(props, { emit }) {
    const chartCanvas = ref(null)
    const chartInstance = ref(null)
    const chartOffset = ref(0)
    const visibleMonths = 12
    const isUpdating = ref(false)
    const canGoPrevious = ref(false)
    const canGoNext = ref(false)
    const chartPeriodText = ref('')

    const getVisibleData = () => {
      if (!props.data?.labels) return { labels: [], datasets: [] }
      const start = chartOffset.value
      const end = Math.min(start + visibleMonths, props.data.labels.length)
      return {
        labels: props.data.labels.slice(start, end),
        datasets: (props.data.datasets || []).map(d => ({ ...d, data: d.data.slice(start, end) }))
      }
    }

    const updateNavigationState = () => {
      if (!props.data?.labels?.length) {
        canGoPrevious.value = false; canGoNext.value = false
        emit('navigation-state', { canGoPrevious: false, canGoNext: false, totalMonths: 0, currentOffset: 0, availableMonths: [] })
        return
      }
      canGoPrevious.value = chartOffset.value > 0
      canGoNext.value = chartOffset.value + 1 < props.data.labels.length
      emit('navigation-state', {
        canGoPrevious: canGoPrevious.value, canGoNext: canGoNext.value,
        totalMonths: props.data.labels.length, currentOffset: chartOffset.value,
        availableMonths: props.data.labels
      })
    }

    const updatePeriodText = () => {
      if (!props.data?.labels?.length) { chartPeriodText.value = ''; return }
      const start = props.data.labels[chartOffset.value] || ''
      const endIdx = Math.min(chartOffset.value + visibleMonths - 1, props.data.labels.length - 1)
      const end = props.data.labels[endIdx] || ''
      chartPeriodText.value = start === end ? start : `${start} ～ ${end}`
    }

    const createChart = () => {
      if (!chartCanvas.value?.isConnected || !props.data?.labels) return
      if (chartOffset.value === 0 && props.data.labels.length > visibleMonths) {
        chartOffset.value = props.data.labels.length - visibleMonths
      }
      const visible = getVisibleData()
      if (!visible.labels.length) return
      const datasets = visible.datasets.filter(d =>
        Array.isArray(d.data) && d.data.length > 0 && d.data.every(v => typeof v === 'number' && !isNaN(v))
      )
      if (!datasets.length) return
      const ctx = chartCanvas.value.getContext('2d')
      if (!ctx) return

      chartInstance.value = new Chart(ctx, {
        type: 'bar',
        data: { labels: visible.labels, datasets },
        options: {
          responsive: true,
          maintainAspectRatio: true,
          aspectRatio: 2,
          animation: false,
          transitions: { active: { animation: { duration: 0 } } },
          layout: { padding: { left: 110, right: 20, top: 10, bottom: 10 } },
          scales: {
            x: {
              stacked: true,
              ticks: { maxRotation: 45 },
              categoryPercentage: 1.0,
              barPercentage: 0.9
            },
            y: {
              stacked: true,
              beginAtZero: true,
              ticks: {
                callback: (v) => props.isPrivacyMode ? '¥*******' : ('¥' + v.toLocaleString()).padStart(8, ' '),
                padding: 10
              },
              afterFit: (scale) => { scale.width = 100 }
            }
          },
          plugins: {
            legend: { display: true, position: 'bottom', labels: { usePointStyle: true, padding: 5, font: { size: 11 } } },
            tooltip: {
              callbacks: {
                label: (ctx) => props.isPrivacyMode
                  ? `${ctx.dataset.label}: ¥*******`
                  : `${ctx.dataset.label}: ¥${ctx.parsed.y.toLocaleString()}`,
                footer: (items) => props.isPrivacyMode
                  ? '合計: ¥*******'
                  : '合計: ¥' + items.reduce((s, i) => s + i.parsed.y, 0).toLocaleString()
              }
            }
          },
          interaction: { mode: 'index', intersect: false }
        }
      })
      updateNavigationState()
      updatePeriodText()
    }

    const updateChart = async () => {
      if (isUpdating.value) return
      isUpdating.value = true
      try {
        try { chartInstance.value?.destroy() } catch (e) {}
        chartInstance.value = null
        await nextTick()
        createChart()
      } finally {
        setTimeout(() => { isUpdating.value = false }, 500)
      }
    }

    const shiftChart = async (dir) => {
      if (isUpdating.value) return
      const next = chartOffset.value + dir
      const total = props.data?.labels?.length || 0
      if (next >= 0 && next < total) {
        chartOffset.value = next
        await updateChart()
      }
    }

    onMounted(() => nextTick(() => createChart()))
    watch(() => props.data, (d) => { if (d?.labels?.length && !isUpdating.value) updateChart() }, { deep: true })
    watch(() => props.isPrivacyMode, () => { if (props.data?.labels?.length && !isUpdating.value) updateChart() })
    onBeforeUnmount(() => { try { chartInstance.value?.destroy() } catch (e) {} })

    return { chartCanvas, canGoPrevious, canGoNext, chartPeriodText, shiftChart, isUpdating }
  }
}
</script>

<style lang="scss" scoped>

.expense-chart {}

.chart-nav {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: $sp-5;
  margin-bottom: $sp-4;
}

.nav-btn {
  background: $color-accent;
  color: #ffffff;
  border: none;
  padding: $sp-2 $sp-3;
  border-radius: $radius-sm;
  font-size: $font-size-md;
  transition: $transition-fast;

  &:hover:not(:disabled) { background: $color-accent-hover; }
  &:disabled { background: $color-border; color: $color-text-muted; cursor: not-allowed; }
}

.chart-period {
  font-size: $font-size-base;
  font-weight: $font-weight-semibold;
  color: $color-text-primary;
  min-width: 200px;
  text-align: center;
}

.chart-wrap {
  position: relative;
  width: 100%;
  canvas { display: block; width: 100% !important; height: auto !important; }
}
</style>
