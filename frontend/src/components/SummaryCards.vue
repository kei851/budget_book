<template lang="pug">
.summary-cards
  .summary-card
    .card-label 今月の支出
    .card-value {{ isPrivacyMode ? '¥***' : '¥' + fmt(summary.thisMonth) }}
  .summary-card
    .card-label 月平均支出
    .card-value {{ isPrivacyMode ? '¥***' : '¥' + fmt(summary.monthlyAverage) }}
  .summary-card
    .card-label 最高支出月
    .card-value {{ isPrivacyMode ? '¥***' : '¥' + fmt(summary.maxMonth) }}
  .summary-card
    .card-label 処理データ数
    .card-value {{ summary.dataCount }}件
</template>

<script>
export default {
  name: 'SummaryCards',
  props: {
    summary: {
      type: Object,
      required: true,
      default: () => ({ thisMonth: 0, monthlyAverage: 0, maxMonth: 0, dataCount: 0 })
    },
    isPrivacyMode: { type: Boolean, default: false }
  },
  setup() {
    const fmt = (n) => Number(n).toLocaleString()
    return { fmt }
  }
}
</script>

<style lang="scss" scoped>

.summary-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
  gap: $sp-4;
  margin-top: $sp-6;
}

.summary-card {
  background: $color-surface;
  border: 1px solid $color-border;
  border-radius: $radius-md;
  padding: $sp-5 $sp-4;
  text-align: center;
  box-shadow: $shadow-xs;
}

.card-label {
  font-size: $font-size-sm;
  color: $color-text-secondary;
  margin-bottom: $sp-2;
  font-weight: $font-weight-medium;
}

.card-value {
  font-size: $font-size-xl;
  font-weight: $font-weight-bold;
  color: $color-text-primary;
  letter-spacing: -0.02em;
}
</style>
