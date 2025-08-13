<template lang="pug">
.expense-chart
  .chart-container
    canvas(ref="chartCanvas")
</template>

<script>
import { ref, onMounted, watch, nextTick } from 'vue'
import {
  Chart,
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend
} from 'chart.js'

// Chart.js コンポーネント登録
Chart.register(
  CategoryScale,
  LinearScale,
  BarElement, 
  Title,
  Tooltip,
  Legend
)

export default {
  name: 'ExpenseChart',
  props: {
    data: {
      type: Object,
      required: true
    },
    period: {
      type: String,
      default: '12ヶ月'
    }
  },
  setup(props) {
    const chartCanvas = ref(null)
    const chartInstance = ref(null)
    
    const createChart = () => {
      if (!chartCanvas.value) return
      
      const ctx = chartCanvas.value.getContext('2d')
      
      chartInstance.value = new Chart(ctx, {
        type: 'bar',
        data: props.data,
        options: {
          responsive: true,
          maintainAspectRatio: false,
          scales: {
            x: {
              stacked: true,
              ticks: {
                maxRotation: 45
              }
            },
            y: {
              stacked: true,
              beginAtZero: true,
              ticks: {
                callback: function(value) {
                  return '¥' + value.toLocaleString()
                }
              }
            }
          },
          plugins: {
            legend: {
              display: true,
              position: 'bottom',
              labels: {
                usePointStyle: true,
                padding: 20,
                font: {
                  size: 11
                }
              }
            },
            tooltip: {
              callbacks: {
                label: function(context) {
                  return context.dataset.label + ': ¥' + context.parsed.y.toLocaleString()
                },
                footer: function(tooltipItems) {
                  let total = 0
                  tooltipItems.forEach(function(tooltipItem) {
                    total += tooltipItem.parsed.y
                  })
                  return '合計: ¥' + total.toLocaleString()
                }
              }
            }
          },
          interaction: {
            mode: 'index',
            intersect: false
          }
        }
      })
    }
    
    const updateChart = () => {
      if (chartInstance.value) {
        chartInstance.value.data = props.data
        chartInstance.value.update()
      }
    }
    
    onMounted(() => {
      nextTick(() => {
        createChart()
      })
    })
    
    watch(() => props.data, () => {
      updateChart()
    }, { deep: true })
    
    return {
      chartCanvas
    }
  }
}
</script>

<style lang="scss" scoped>
.expense-chart {
  
  .chart-container {
    position: relative;
    height: 400px;
    margin-bottom: 20px;
  }
}
</style>