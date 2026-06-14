<template lang="pug">
.recurring-card
  .recurring-header
    .recurring-title
      .recurring-icon 🔄
      span 定期支出
    .recurring-subtitle 直近6ヶ月で3回以上の支出

  .recurring-loading(v-if="loading")
    .loading-dots
      span
      span
      span

  .recurring-empty(v-else-if="!loading && items.length === 0")
    p.empty-text 定期支出は検出されませんでした

  .recurring-list(v-else)
    .recurring-item(v-for="item in items" :key="item.store_name")
      .recurring-item-left
        .recurring-category-dot(:style="{ background: item.category_color }")
        .recurring-item-info
          .recurring-store(:title="item.store_name") {{ item.store_name }}
          .recurring-meta
            span.recurring-category {{ item.category_name }}
            span.recurring-freq ・{{ item.month_count }}ヶ月連続
      .recurring-item-right
        .recurring-amount(:class="{ privacy: isPrivacyMode }")
          | {{ isPrivacyMode ? '¥***' : '¥' + item.estimated_monthly.toLocaleString() }}
        .recurring-label /月
</template>

<script>
import { ref, onMounted } from 'vue'
import apiService from '../services/api.js'

export default {
  name: 'RecurringCard',
  props: {
    isPrivacyMode: { type: Boolean, default: false }
  },
  setup() {
    const items = ref([])
    const loading = ref(false)

    const load = async () => {
      loading.value = true
      try {
        items.value = await apiService.getRecurring()
      } catch (_) {
        items.value = []
      } finally {
        loading.value = false
      }
    }

    onMounted(load)
    return { items, loading }
  }
}
</script>

<style lang="scss" scoped>
.recurring-card {
  background: $color-surface;
  border: 1px solid $color-border-light;
  border-radius: $radius-lg;
  padding: $sp-6;
  box-shadow: $shadow-sm;
}

.recurring-header {
  margin-bottom: $sp-5;
}

.recurring-title {
  display: flex;
  align-items: center;
  gap: $sp-2;
  font-size: $font-size-md;
  font-weight: $font-weight-semibold;
  color: $color-text-primary;
  margin-bottom: 2px;
}

.recurring-icon { font-size: 1.1rem; }

.recurring-subtitle {
  font-size: $font-size-xs;
  color: $color-text-muted;
  margin-top: $sp-1;
}

.recurring-loading {
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

.recurring-empty {
  padding: $sp-6 0;
  text-align: center;

  .empty-text {
    font-size: $font-size-sm;
    color: $color-text-muted;
  }
}

.recurring-list {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.recurring-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: $sp-3;
  border-radius: $radius-sm;
  transition: $transition-fast;

  &:hover { background: $color-surface-sub; }
}

.recurring-item-left {
  display: flex;
  align-items: center;
  gap: $sp-3;
  min-width: 0;
}

.recurring-category-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  flex-shrink: 0;
}

.recurring-store {
  font-size: $font-size-sm;
  font-weight: $font-weight-medium;
  color: $color-text-primary;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 160px;
}

.recurring-meta {
  font-size: $font-size-xs;
  color: $color-text-muted;
  margin-top: 1px;
}

.recurring-category { color: $color-text-secondary; }
.recurring-freq { color: $color-accent; font-weight: $font-weight-medium; }

.recurring-item-right {
  display: flex;
  align-items: baseline;
  gap: 2px;
  flex-shrink: 0;
  margin-left: $sp-3;
}

.recurring-amount {
  font-size: $font-size-base;
  font-weight: $font-weight-bold;
  color: $color-text-primary;
}

.recurring-label {
  font-size: $font-size-xs;
  color: $color-text-muted;
}
</style>
