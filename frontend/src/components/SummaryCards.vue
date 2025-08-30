<template lang="pug">
.summary-cards
  .summary-card.summary-card--red
    .summary-card__title 今月の支出
    .summary-card__value {{ isPrivacyMode ? '¥***' : '¥' + formatNumber(summary.thisMonth) }}
  
  .summary-card.summary-card--green  
    .summary-card__title 月平均支出
    .summary-card__value {{ isPrivacyMode ? '¥***' : '¥' + formatNumber(summary.monthlyAverage) }}
  
  .summary-card.summary-card--blue
    .summary-card__title 最高支出月
    .summary-card__value {{ isPrivacyMode ? '¥***' : '¥' + formatNumber(summary.maxMonth) }}
  
  .summary-card.summary-card--orange
    .summary-card__title 処理データ数
    .summary-card__value {{ summary.dataCount }}件
</template>

<script>
export default {
  name: 'SummaryCards',
  props: {
    summary: {
      type: Object,
      required: true,
      default: () => ({
        thisMonth: 0,
        monthlyAverage: 0,
        maxMonth: 0,
        dataCount: 0
      })
    },
    isPrivacyMode: {
      type: Boolean,
      default: false
    }
  },
  setup(props) {
    const formatNumber = (num) => {
      return num.toLocaleString()
    }
    
    return {
      formatNumber
    }
  }
}
</script>

<style lang="scss" scoped>
.summary-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 20px;
  margin-top: 30px;
}

.summary-card {
  color: white;
  padding: 25px;
  border-radius: 10px;
  text-align: center;
  
  &--red {
    background: linear-gradient(135deg, #7dd3fc 0%, #38bdf8 100%);
  }
  
  &--green {
    background: linear-gradient(135deg, #7dd3fc 0%, #38bdf8 100%);
  }
  
  &--blue {
    background: linear-gradient(135deg, #7dd3fc 0%, #38bdf8 100%);
  }
  
  &--orange {
    background: linear-gradient(135deg, #7dd3fc 0%, #38bdf8 100%);
  }
  
  &__title {
    font-size: 0.9em;
    opacity: 0.9;
    margin-bottom: 10px;
  }
  
  &__value {
    font-size: 2em;
    font-weight: bold;
  }
}
</style>