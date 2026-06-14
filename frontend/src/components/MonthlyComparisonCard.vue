<template lang="pug">
.comparison-card
  .comparison-header
    .comparison-title
      .comparison-icon 📈
      span 前月比較

  .comparison-loading(v-if="loading")
    .loading-dots
      span
      span
      span

  .comparison-body(v-else-if="data")
    .comparison-grid
      .period-col(v-for="period in periods" :key="period.key")
        .period-label {{ period.label }}
        .period-total(:class="{ privacy: isPrivacyMode }")
          | {{ isPrivacyMode ? '¥***' : '¥' + period.total.toLocaleString() }}
        .period-diff(v-if="period.diff !== null" :class="diffClass(period.diff)")
          span {{ diffLabel(period.diff) }}

    .category-comparison
      .category-row(v-for="cat in topCategories" :key="cat.name")
        .cat-dot(:style="{ background: cat.color }")
        .cat-name {{ cat.name }}
        .cat-bars
          .cat-bar-wrap(v-for="period in periods" :key="period.key")
            .cat-bar(
              :style="{ width: barWidth(cat, period) + '%', background: cat.color, opacity: period.key === 'current' ? 1 : 0.4 }"
            )
        .cat-amount {{ isPrivacyMode ? '¥***' : '¥' + (catAmount(cat.name, 'current') || 0).toLocaleString() }}
</template>

<script>
import { ref, computed, watch } from 'vue'
import apiService from '../services/api.js'

export default {
  name: 'MonthlyComparisonCard',
  props: {
    year: { type: Number, required: true },
    month: { type: Number, required: true },
    isPrivacyMode: { type: Boolean, default: false }
  },
  setup(props) {
    const data = ref(null)
    const loading = ref(false)

    const load = async () => {
      loading.value = true
      try {
        data.value = await apiService.getMonthlyComparison(props.year, props.month)
      } catch (_) {
        data.value = null
      } finally {
        loading.value = false
      }
    }

    const periods = computed(() => {
      if (!data.value) return []
      const cur = data.value.current?.total || 0
      const prv = data.value.prev_month?.total || 0
      const pry = data.value.prev_year?.total || 0
      return [
        { key: 'current', label: data.value.current?.label || '今月', total: cur, diff: null },
        { key: 'prev_month', label: data.value.prev_month?.label || '先月', total: prv, diff: cur - prv },
        { key: 'prev_year', label: data.value.prev_year?.label || '前年同月', total: pry, diff: cur - pry },
      ]
    })

    const topCategories = computed(() => {
      if (!data.value?.current?.by_category) return []
      const allNames = new Set([
        ...data.value.current.by_category.map(c => c.name),
        ...(data.value.prev_month?.by_category || []).map(c => c.name)
      ])
      return Array.from(allNames).map(name => {
        const cur = data.value.current.by_category.find(c => c.name === name)
        return { name, color: cur?.color || '#ccc', current: cur?.amount || 0 }
      }).sort((a, b) => b.current - a.current).slice(0, 5)
    })

    const catAmount = (name, periodKey) => {
      if (!data.value?.[periodKey]?.by_category) return 0
      return data.value[periodKey].by_category.find(c => c.name === name)?.amount || 0
    }

    const maxAmount = computed(() => {
      if (!topCategories.value.length) return 1
      return Math.max(...topCategories.value.map(c => c.current), 1)
    })

    const barWidth = (cat, period) => {
      const amt = catAmount(cat.name, period.key)
      return Math.round((amt / maxAmount.value) * 100)
    }

    const diffClass = (diff) => diff > 0 ? 'diff-up' : diff < 0 ? 'diff-down' : 'diff-flat'
    const diffLabel = (diff) => {
      if (diff === 0) return '±0'
      const sign = diff > 0 ? '▲' : '▼'
      return `${sign} ¥${Math.abs(diff).toLocaleString()}`
    }

    watch([() => props.year, () => props.month], load, { immediate: true })

    return { data, loading, periods, topCategories, catAmount, barWidth, diffClass, diffLabel }
  }
}
</script>

<style lang="scss" scoped>
.comparison-card {
  background: $color-surface;
  border: 1px solid $color-border-light;
  border-radius: $radius-lg;
  padding: $sp-6;
  box-shadow: $shadow-sm;
}

.comparison-header {
  margin-bottom: $sp-5;
}

.comparison-title {
  display: flex;
  align-items: center;
  gap: $sp-2;
  font-size: $font-size-md;
  font-weight: $font-weight-semibold;
  color: $color-text-primary;
}

.comparison-icon { font-size: 1.1rem; }

.comparison-loading {
  display: flex;
  justify-content: center;
  padding: $sp-8 0;
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

.comparison-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: $sp-3;
  margin-bottom: $sp-6;
}

.period-col {
  background: $color-surface-sub;
  border-radius: $radius-md;
  padding: $sp-4;
  text-align: center;
  border: 1px solid $color-border-light;
}

.period-label {
  font-size: $font-size-xs;
  color: $color-text-muted;
  margin-bottom: $sp-1;
}

.period-total {
  font-size: $font-size-md;
  font-weight: $font-weight-bold;
  color: $color-text-primary;
  margin-bottom: $sp-1;
}

.period-diff {
  font-size: $font-size-xs;
  font-weight: $font-weight-semibold;

  &.diff-up { color: #ef4444; }
  &.diff-down { color: $color-success; }
  &.diff-flat { color: $color-text-muted; }
}

.category-comparison {
  display: flex;
  flex-direction: column;
  gap: $sp-3;
}

.category-row {
  display: flex;
  align-items: center;
  gap: $sp-2;
}

.cat-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  flex-shrink: 0;
}

.cat-name {
  font-size: $font-size-xs;
  color: $color-text-secondary;
  width: 56px;
  flex-shrink: 0;
}

.cat-bars {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.cat-bar-wrap {
  height: 6px;
  background: $color-border-light;
  border-radius: $radius-full;
  overflow: hidden;
}

.cat-bar {
  height: 100%;
  border-radius: $radius-full;
  transition: width 0.4s ease;
  min-width: 2px;
}

.cat-amount {
  font-size: $font-size-xs;
  font-weight: $font-weight-semibold;
  color: $color-text-primary;
  min-width: 72px;
  text-align: right;
}
</style>
