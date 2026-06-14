<template lang="pug">
.ai-summary-card
  .ai-summary-header
    .ai-summary-title
      .ai-icon ✨
      span AIサマリ
    .ai-summary-actions(v-if="summary")
      button.btn-refresh(@click="generate" :disabled="isLoading")
        svg(viewBox="0 0 24 24" width="14" height="14" fill="currentColor")
          path(d="M17.65 6.35A7.958 7.958 0 0 0 12 4c-4.42 0-7.99 3.58-7.99 8s3.57 8 7.99 8c3.73 0 6.84-2.55 7.73-6h-2.08A5.99 5.99 0 0 1 12 18c-3.31 0-6-2.69-6-6s2.69-6 6-6c1.66 0 3.14.69 4.22 1.78L13 11h7V4l-2.35 2.35z")
        span 更新

  .ai-summary-body
    .ai-loading(v-if="isLoading")
      .loading-dots
        span
        span
        span
      span.loading-text Claudeが分析中...

    .ai-summary-text(v-else-if="summary") {{ summary }}

    .ai-empty(v-else)
      p.ai-empty-desc このページの支出データをClaudeが日本語でナラティブ分析します。
      button.btn-generate(@click="generate" :disabled="isLoading")
        span ✨ AIサマリを生成
</template>

<script>
import { ref, watch } from 'vue'
import apiService from '../services/api.js'

export default {
  name: 'AiSummaryCard',
  props: {
    year: { type: Number, required: true },
    month: { type: Number, required: true }
  },
  setup(props) {
    const summary = ref(null)
    const isLoading = ref(false)

    const generate = async () => {
      if (isLoading.value) return
      isLoading.value = true
      summary.value = null
      try {
        const res = await apiService.getAiMonthlySummary(props.year, props.month)
        summary.value = res.summary
      } catch (e) {
        summary.value = 'サマリの生成に失敗しました。APIキーの設定を確認してください。'
      } finally {
        isLoading.value = false
      }
    }

    watch([() => props.year, () => props.month], () => { summary.value = null })

    return { summary, isLoading, generate }
  }
}
</script>

<style lang="scss" scoped>
.ai-summary-card {
  background: linear-gradient(135deg, #f0f7ff 0%, #faf5ff 100%);
  border: 1px solid #c7d9f0;
  border-radius: $radius-lg;
  padding: $sp-6;
  box-shadow: $shadow-sm;
}

.ai-summary-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: $sp-4;
}

.ai-summary-title {
  display: flex;
  align-items: center;
  gap: $sp-2;
  font-size: $font-size-md;
  font-weight: $font-weight-semibold;
  color: $color-text-primary;

  .ai-icon {
    font-size: 1.1rem;
  }
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

.ai-summary-text {
  font-size: $font-size-base;
  color: $color-text-primary;
  line-height: 1.8;
  white-space: pre-wrap;
  padding: $sp-2 0;
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
