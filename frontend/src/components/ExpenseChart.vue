<template lang="pug">
.expense-chart
  .scroll-hint(v-if="showScrollHint") ← → 左右にスクロールできます
  .chart-container
    canvas(ref="chartCanvas")
</template>

<script>
import { ref, onMounted, onBeforeUnmount, watch, nextTick } from 'vue'
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
    isPrivacyMode: {
      type: Boolean,
      default: false
    }
  },
  setup(props) {
    const chartCanvas = ref(null)
    const chartInstance = ref(null)
    const showScrollHint = ref(false)
    
    const createChart = () => {
      if (!chartCanvas.value || !props.data) return
      
      try {
        // データ数に応じてCanvasサイズを動的計算
        const monthCount = props.data.labels ? props.data.labels.length : 12
        const chartWidth = Math.max(1000, monthCount * 80) // 月あたり80px、最低1000px
        
        // スクロールヒントの表示判定
        showScrollHint.value = chartWidth > 1000
        
        const ctx = chartCanvas.value.getContext('2d')
      
      chartInstance.value = new Chart(ctx, {
        type: 'bar',
        data: props.data,
        options: {
          responsive: false,
          maintainAspectRatio: false,
          width: chartWidth,
          height: 400,
          layout: {
            padding: 20
          },
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
                  return props.isPrivacyMode ? '¥***' : '¥' + value.toLocaleString()
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
                  if (props.isPrivacyMode) {
                    return context.dataset.label + ': ¥***'
                  } else {
                    return context.dataset.label + ': ¥' + context.parsed.y.toLocaleString()
                  }
                },
                footer: function(tooltipItems) {
                  if (props.isPrivacyMode) {
                    return '合計: ¥***'
                  } else {
                    let total = 0
                    tooltipItems.forEach(function(tooltipItem) {
                      total += tooltipItem.parsed.y
                    })
                    return '合計: ¥' + total.toLocaleString()
                  }
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
      
      // Chart.js作成後にCanvasサイズを設定
      if (chartInstance.value) {
        chartCanvas.value.style.width = chartWidth + 'px'
        chartCanvas.value.style.height = '400px'
        chartInstance.value.resize(chartWidth, 400)
      }
      
      } catch (error) {
        console.error('Chart creation error:', error)
      }
    }
    
    const updateChart = () => {
      if (chartInstance.value) {
        try {
          // 既存のチャートを破棄
          chartInstance.value.destroy()
        } catch (error) {
          console.warn('Chart destroy error:', error)
        }
        chartInstance.value = null
      }
      
      // 新しいチャートを作成
      nextTick(() => {
        createChart()
      })
    }
    
    onMounted(() => {
      nextTick(() => {
        createChart()
      })
    })
    
    watch(() => props.data, (newData) => {
      if (newData && newData.labels && newData.datasets) {
        updateChart()
      }
    }, { deep: true })
    
    // プライバシーモード変更時もチャートを再描画
    watch(() => props.isPrivacyMode, () => {
      if (props.data && props.data.labels && props.data.datasets) {
        updateChart()
      }
    })
    
    onBeforeUnmount(() => {
      if (chartInstance.value) {
        try {
          chartInstance.value.destroy()
        } catch (error) {
          console.warn('Chart destroy error on unmount:', error)
        }
        chartInstance.value = null
      }
    })
    
    return {
      chartCanvas,
      showScrollHint
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
    overflow-x: auto;
    overflow-y: hidden;
    border: 1px solid #ddd; // スクロールエリアを明確化
    
    canvas {
      display: block;
      // widthとheightはJavaScriptで動的設定
    }
  }
  
  // スクロールバーのスタイル調整
  .chart-container::-webkit-scrollbar {
    height: 8px;
  }
  
  .chart-container::-webkit-scrollbar-track {
    background: #f1f1f1;
    border-radius: 4px;
  }
  
  .chart-container::-webkit-scrollbar-thumb {
    background: #888;
    border-radius: 4px;
  }
  
  .chart-container::-webkit-scrollbar-thumb:hover {
    background: #555;
  }
  
  .scroll-hint {
    text-align: center;
    color: #666;
    font-size: 12px;
    margin-bottom: 10px;
    padding: 5px;
    background: #f0f8ff;
    border-radius: 4px;
    border: 1px dashed #4CAF50;
  }
}
</style>