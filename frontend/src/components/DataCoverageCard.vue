<template lang="pug">
.coverage-card(v-if="coverage || histories.length > 0")
  .coverage-header
    .coverage-title
      .coverage-icon 📂
      span 取り込み済みデータ
    button.coverage-refresh(@click="load" :disabled="loading")
      svg(viewBox="0 0 24 24" width="13" height="13" fill="currentColor")
        path(d="M17.65 6.35A7.958 7.958 0 0 0 12 4c-4.42 0-7.99 3.58-7.99 8s3.57 8 7.99 8c3.73 0 6.84-2.55 7.73-6h-2.08A5.99 5.99 0 0 1 12 18c-3.31 0-6-2.69-6-6s2.69-6 6-6c1.66 0 3.14.69 4.22 1.78L13 11h7V4l-2.35 2.35z")

  .coverage-loading(v-if="loading")
    .loading-dots: span
    .loading-dots: span
    .loading-dots: span

  template(v-else)
    .coverage-summary(v-if="coverage?.label")
      .coverage-range-block
        .coverage-label 取り込み期間
        .coverage-range {{ coverage.label }}
      .coverage-divider
      .coverage-range-block
        .coverage-label 総取引件数
        .coverage-range {{ coverage.total_transactions.toLocaleString() }}件

    .coverage-empty(v-else)
      p.empty-text まだデータが取り込まれていません

    .history-timeline(v-if="histories.length > 0")
      .timeline-label ファイル別内訳
      .timeline-items
        .timeline-item(v-for="h in histories" :key="h.id")
          .timeline-source(:class="h.data_source_type")
            | {{ sourceLabel(h.data_source_type) }}
          .timeline-body
            .timeline-filename {{ h.filename }}
            .timeline-range(v-if="h.date_range_label") 📅 {{ h.date_range_label }}
            .timeline-count {{ h.imported_count.toLocaleString() }}件
          .timeline-upload 取込: {{ formatUploadDate(h.upload_date) }}
</template>

<script>
import { ref, onMounted } from 'vue'
import apiService from '../services/api.js'

export default {
  name: 'DataCoverageCard',
  setup() {
    const coverage = ref(null)
    const histories = ref([])
    const loading = ref(false)

    const load = async () => {
      loading.value = true
      try {
        const res = await apiService.getUploadHistories()
        coverage.value = res.coverage
        histories.value = res.upload_histories || []
      } catch (_) {
      } finally {
        loading.value = false
      }
    }

    const sourceLabel = (type) => {
      if (type === 'rakuten') return '楽天カード'
      if (type === 'rakuten_bank') return '楽天銀行'
      if (type === 'epos') return 'EPOS'
      return type || '—'
    }

    const formatUploadDate = (dateStr) => {
      if (!dateStr) return ''
      return dateStr.replace(' JST', '').split(' ')[0]
    }

    onMounted(load)
    return { coverage, histories, loading, load, sourceLabel, formatUploadDate }
  }
}
</script>

<style lang="scss" scoped>
.coverage-card {
  background: $color-surface;
  border: 1px solid $color-border-light;
  border-radius: $radius-lg;
  padding: $sp-5;
  box-shadow: $shadow-xs;
}

.coverage-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: $sp-4;
}

.coverage-title {
  display: flex;
  align-items: center;
  gap: $sp-2;
  font-size: $font-size-base;
  font-weight: $font-weight-semibold;
  color: $color-text-primary;
}

.coverage-icon { font-size: 1rem; }

.coverage-refresh {
  background: none;
  border: none;
  color: $color-text-muted;
  cursor: pointer;
  padding: $sp-1;
  border-radius: $radius-sm;
  display: flex;
  align-items: center;
  transition: $transition-fast;

  &:hover:not(:disabled) { color: $color-accent; background: $color-accent-light; }
  &:disabled { opacity: 0.4; cursor: not-allowed; }
}

.coverage-loading {
  display: flex;
  gap: 4px;
  padding: $sp-4 0;
  justify-content: center;
}

.loading-dots span {
  width: 6px;
  height: 6px;
  background: $color-accent;
  border-radius: 50%;
  display: block;
  animation: dot-bounce 1.2s infinite ease-in-out;
}

@keyframes dot-bounce {
  0%, 80%, 100% { transform: scale(0.6); opacity: 0.5; }
  40% { transform: scale(1); opacity: 1; }
}

.coverage-summary {
  display: flex;
  align-items: center;
  gap: $sp-4;
  background: linear-gradient(135deg, $color-accent-light, #faf5ff);
  border: 1px solid #c7d9f0;
  border-radius: $radius-md;
  padding: $sp-4 $sp-5;
  margin-bottom: $sp-4;
}

.coverage-range-block {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.coverage-label {
  font-size: $font-size-xs;
  color: $color-text-muted;
}

.coverage-range {
  font-size: $font-size-md;
  font-weight: $font-weight-bold;
  color: $color-accent;
}

.coverage-divider {
  width: 1px;
  height: 36px;
  background: $color-border;
}

.coverage-empty {
  text-align: center;
  padding: $sp-4 0;

  .empty-text {
    font-size: $font-size-sm;
    color: $color-text-muted;
  }
}

.history-timeline {
  margin-top: $sp-2;
}

.timeline-label {
  font-size: $font-size-xs;
  color: $color-text-muted;
  font-weight: $font-weight-medium;
  margin-bottom: $sp-2;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.timeline-items {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.timeline-item {
  display: flex;
  align-items: center;
  gap: $sp-3;
  padding: $sp-2 + 2 $sp-3;
  background: $color-surface-sub;
  border-radius: $radius-sm;
  border: 1px solid $color-border-light;
}

.timeline-source {
  font-size: $font-size-xs;
  font-weight: $font-weight-bold;
  padding: 2px $sp-2;
  border-radius: $radius-full;
  flex-shrink: 0;

  &.rakuten {
    background: #fff0f3;
    color: #c0392b;
  }
  &.rakuten_bank {
    background: #fff0f3;
    color: #c0392b;
  }
  &.epos {
    background: #fff8e1;
    color: #b87500;
  }
}

.timeline-body {
  flex: 1;
  min-width: 0;
}

.timeline-filename {
  font-size: $font-size-xs;
  color: $color-text-secondary;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.timeline-range {
  font-size: $font-size-sm;
  font-weight: $font-weight-medium;
  color: $color-text-primary;
  margin-top: 1px;
}

.timeline-count {
  font-size: $font-size-xs;
  color: $color-text-muted;
}

.timeline-upload {
  font-size: $font-size-xs;
  color: $color-text-muted;
  flex-shrink: 0;
  white-space: nowrap;
}
</style>
