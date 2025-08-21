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

.analytics-button-container
  button.analytics-btn(@click="$emit('navigate-to-analytics')") 📊 詳細分析を見る
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
  emits: ['navigate-to-analytics'],
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
    background: linear-gradient(135deg, #ff7675 0%, #fd79a8 100%);
  }
  
  &--green {
    background: linear-gradient(135deg, #00b894 0%, #00cec9 100%);
  }
  
  &--blue {
    background: linear-gradient(135deg, #0984e3 0%, #74b9ff 100%);
  }
  
  &--orange {
    background: linear-gradient(135deg, #e17055 0%, #fdcb6e 100%);
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

.analytics-button-container {
  text-align: center;
  margin-top: 30px;
}

.analytics-btn {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  padding: 15px 30px;
  border-radius: 25px;
  font-size: 1.1em;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
  
  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 6px 20px rgba(102, 126, 234, 0.4);
  }
}
</style>