<template lang="pug">
.expense-chart
  .chart-controls
    button.nav-btn(:disabled="!canGoPrevious || isUpdating" @click="shiftChart(-1)") ←
    span.chart-period {{ chartPeriodText }}
    button.nav-btn(:disabled="!canGoNext || isUpdating" @click="shiftChart(1)") →
  .chart-container
    .chart-wrapper(ref="chartWrapper")
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
  emits: ['navigation-state'],
  setup(props, { emit }) {
    const chartCanvas = ref(null)
    const chartWrapper = ref(null)
    const chartInstance = ref(null)
    const pieChartCanvas = ref(null)
    const pieChartInstance = ref(null)
    const chartLegend = ref(null)
    const chartOffset = ref(0) // 表示開始位置
    const visibleMonths = 12 // 一度に表示する月数
    const isUpdating = ref(false) // チャート更新中フラグ
    
    // 初期表示で最新月が右端に来るようにオフセットを計算
    const calculateInitialOffset = () => {
      if (!props.data || !props.data.labels || props.data.labels.length <= visibleMonths) {
        return 0
      }
      return props.data.labels.length - visibleMonths
    }
    
    // 表示用データを計算
    const getVisibleData = () => {
      if (!props.data || !props.data.labels) return { labels: [], datasets: [] }
      
      const allLabels = props.data.labels
      const allDatasets = props.data.datasets || []
      
      const startIdx = chartOffset.value
      const endIdx = Math.min(startIdx + visibleMonths, allLabels.length)
      
      const visibleLabels = allLabels.slice(startIdx, endIdx)
      const visibleDatasets = allDatasets.map(dataset => ({
        ...dataset,
        data: dataset.data.slice(startIdx, endIdx)
      }))
      
      return { labels: visibleLabels, datasets: visibleDatasets }
    }
    
    // 前後移動の可否を計算
    const canGoPrevious = ref(false)
    const canGoNext = ref(false)
    
    const updateNavigationState = () => {
      if (!props.data || !props.data.labels || !props.data.datasets) {
        canGoPrevious.value = false
        canGoNext.value = false
        emit('navigation-state', { 
          canGoPrevious: false, 
          canGoNext: false, 
          totalMonths: 0, 
          currentOffset: 0,
          availableMonths: []
        })
        return
      }
      
      // 正しい判定ロジック
      // 左矢印: オフセットが0より大きい = 前に戻れる
      canGoPrevious.value = chartOffset.value > 0
      
      // 右矢印: 現在の表示終了位置が全データより小さい = 先に進める
      canGoNext.value = (chartOffset.value + visibleMonths) < props.data.labels.length
      
      // ナビゲーション状態を親コンポーネントに通知
      emit('navigation-state', {
        canGoPrevious: canGoPrevious.value,
        canGoNext: canGoNext.value,
        totalMonths: props.data.labels.length,
        currentOffset: chartOffset.value,
        availableMonths: props.data.labels || []
      })
    }
    
    // 表示期間テキスト
    const chartPeriodText = ref('')
    
    const updatePeriodText = () => {
      if (!props.data || !props.data.labels || props.data.labels.length === 0) {
        chartPeriodText.value = ''
        return
      }
      
      const startLabel = props.data.labels[chartOffset.value] || ''
      const endIdx = Math.min(chartOffset.value + visibleMonths - 1, props.data.labels.length - 1)
      const endLabel = props.data.labels[endIdx] || ''
      
      if (startLabel === endLabel) {
        chartPeriodText.value = startLabel
      } else {
        chartPeriodText.value = `${startLabel} ～ ${endLabel}`
      }
    }

    const createChart = () => {
      if (!chartCanvas.value || !props.data) {
        console.warn('Chart creation skipped: canvas or data not available')
        return
      }
      
      // canvas要素が正しくDOMに存在するかチェック
      if (!chartCanvas.value.isConnected) {
        console.warn('Chart creation skipped: canvas not connected to DOM')
        return
      }
      
      // 初回作成時は最新月が右端に来るようにオフセットを設定
      if (chartOffset.value === 0 && props.data.labels && props.data.labels.length > visibleMonths) {
        chartOffset.value = calculateInitialOffset()
      }
      
      try {
        const visibleData = getVisibleData()
        if (!visibleData.labels.length) return
        
        // データセットのvalidation
        if (!visibleData.datasets || visibleData.datasets.length === 0) {
          console.warn('Chart creation skipped: no valid datasets')
          return
        }
        
        // 各データセットのデータ配列をvalidation
        const validDatasets = visibleData.datasets.filter(dataset => {
          return dataset && 
                 Array.isArray(dataset.data) && 
                 dataset.data.length > 0 &&
                 dataset.data.every(val => typeof val === 'number' && !isNaN(val))
        })
        
        if (validDatasets.length === 0) {
          console.warn('Chart creation skipped: no valid datasets after validation')
          return
        }
        
        const ctx = chartCanvas.value.getContext('2d')
        if (!ctx) {
          console.warn('Chart creation skipped: cannot get 2d context')
          return
        }
      
      chartInstance.value = new Chart(ctx, {
        type: 'bar',
        data: {
          labels: visibleData.labels,
          datasets: validDatasets
        },
        options: {
          responsive: true,
          maintainAspectRatio: true,
          aspectRatio: 2,
          animation: false, // アニメーションを無効化
          transitions: {
            active: {
              animation: {
                duration: 0
              }
            }
          },
          layout: {
            padding: {
              left: 110, // Y軸の幅に余裕を持たせて固定
              right: 20,
              top: 10,
              bottom: 10
            }
          },
          scales: {
            x: {
              stacked: true,
              ticks: {
                maxRotation: 45
              },
              grid: {
                offset: false
              },
              categoryPercentage: 1.0,
              barPercentage: 0.9
            },
            y: {
              stacked: true,
              beginAtZero: true,
              ticks: {
                callback: function(value) {
                  if (props.isPrivacyMode) {
                    // プライバシーモード時は固定桁数で統一表示
                    return '¥*******'
                  } else {
                    // 通常モード時も桁数を意識した表示
                    const formattedValue = '¥' + value.toLocaleString()
                    return formattedValue.padStart(8, ' ') // 最小8桁で右揃え
                  }
                },
                // 軸の幅を固定するため、最小幅を設定
                minWidth: 100,
                // ラベルの文字数を統一するため、右揃えパディングを追加
                padding: 10
              },
              grid: {
                offset: false
              },
              // Y軸の幅を固定
              position: 'left',
              // チャートエリアの左マージンを固定
              afterFit: function(scale) {
                scale.width = 100; // 固定幅を設定
              }
            }
          },
          plugins: {
            legend: {
              display: true,
              position: 'bottom',
              labels: {
                usePointStyle: true,
                padding: 5,
                font: {
                  size: 11
                }
              }
            },
            tooltip: {
              callbacks: {
                label: function(context) {
                  if (props.isPrivacyMode) {
                    return context.dataset.label + ': ¥*******'
                  } else {
                    return context.dataset.label + ': ¥' + context.parsed.y.toLocaleString()
                  }
                },
                footer: function(tooltipItems) {
                  if (props.isPrivacyMode) {
                    return '合計: ¥*******'
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
      
      // ナビゲーション状態と期間テキストを更新
      updateNavigationState()
      updatePeriodText()
      
      // パイチャートも作成
      createPieChart()
      
      } catch (error) {
        console.error('Chart creation error:', error)
      }
    }
    
    const createPieChart = () => {
      if (!pieChartCanvas.value || !props.data) {
        console.warn('Pie chart creation skipped: canvas or data not available')
        return
      }
      
      // canvas要素が正しくDOMに存在するかチェック
      if (!pieChartCanvas.value.isConnected) {
        console.warn('Pie chart creation skipped: canvas not connected to DOM')
        return
      }
      
      try {
        // 現在表示中のデータから各カテゴリの合計値を計算
        const visibleData = getVisibleData()
        if (!visibleData.datasets || visibleData.datasets.length === 0) {
          console.warn('Pie chart creation skipped: no valid datasets')
          return
        }
        
        // 各カテゴリの合計額を計算
        const categoryTotals = visibleData.datasets.map(dataset => {
          const total = dataset.data.reduce((sum, value) => sum + value, 0)
          return {
            label: dataset.label,
            value: total,
            color: dataset.backgroundColor
          }
        }).filter(item => item.value > 0) // 0円のカテゴリは除外
        
        if (categoryTotals.length === 0) {
          console.warn('Pie chart creation skipped: no data with values > 0')
          return
        }
        
        const pieCtx = pieChartCanvas.value.getContext('2d')
        if (!pieCtx) {
          console.warn('Pie chart creation skipped: cannot get 2d context')
          return
        }
        
        pieChartInstance.value = new Chart(pieCtx, {
          type: 'doughnut',
          data: {
            labels: categoryTotals.map(item => item.label),
            datasets: [{
              data: categoryTotals.map(item => item.value),
              backgroundColor: categoryTotals.map(item => item.color),
              borderWidth: 0,
              hoverBorderWidth: 2,
              hoverBorderColor: '#fff'
            }]
          },
          options: {
            responsive: true,
            maintainAspectRatio: true,
            aspectRatio: 1,
            animation: false,
            cutout: '50%',
            plugins: {
              legend: {
                display: false // カスタム凡例を使用するため無効化
              },
              tooltip: {
                callbacks: {
                  label: function(context) {
                    if (props.isPrivacyMode) {
                      return context.label + ': ¥*******'
                    } else {
                      return context.label + ': ¥' + context.parsed.toLocaleString()
                    }
                  }
                }
              }
            }
          }
        })
        
        // カスタム凡例を生成
        generateCustomLegend(categoryTotals)
        
      } catch (error) {
        console.error('Pie chart creation error:', error)
      }
    }
    
    const generateCustomLegend = (categoryTotals) => {
      const legendContainer = chartLegend.value
      if (!legendContainer) return
      
      // 既存の凡例をクリア
      legendContainer.innerHTML = ''
      
      categoryTotals.forEach(item => {
        const legendItem = document.createElement('div')
        legendItem.className = 'legend-item'
        
        const colorBox = document.createElement('div')
        colorBox.className = 'legend-color'
        colorBox.style.backgroundColor = item.color
        
        const labelText = document.createElement('span')
        labelText.className = 'legend-label'
        labelText.textContent = item.label
        
        const valueText = document.createElement('span')
        valueText.className = 'legend-value'
        if (props.isPrivacyMode) {
          valueText.textContent = '¥*******'
        } else {
          valueText.textContent = '¥' + item.value.toLocaleString()
        }
        
        legendItem.appendChild(colorBox)
        legendItem.appendChild(labelText)
        legendItem.appendChild(valueText)
        legendContainer.appendChild(legendItem)
      })
    }
    
    const updateChart = async () => {
      if (isUpdating.value) return // 既に更新中の場合は処理を中断
      
      isUpdating.value = true
      
      try {
        if (chartInstance.value) {
          try {
            // 既存のチャートを破棄
            chartInstance.value.destroy()
          } catch (error) {
            console.warn('Chart destroy error:', error)
          }
          chartInstance.value = null
        }
        
        if (pieChartInstance.value) {
          try {
            // 既存のパイチャートを破棄
            pieChartInstance.value.destroy()
          } catch (error) {
            console.warn('Pie chart destroy error:', error)
          }
          pieChartInstance.value = null
        }
        
        // 新しいチャートを作成
        await nextTick()
        createChart()
      } catch (error) {
        console.error('Chart update error:', error)
      } finally {
        // より長い遅延を入れて確実にChart.jsが安定してから次の処理を許可
        setTimeout(() => {
          isUpdating.value = false
        }, 500)
      }
    }
    
    // 矢印移動機能（デバウンス付き）
    const shiftChart = async (direction) => {
      if (isUpdating.value) return // 更新中は処理をスキップ
      
      const newOffset = chartOffset.value + direction
      const totalData = props.data?.labels?.length || 0
      
      // 範囲チェック：0以上、かつ表示可能な範囲内
      if (newOffset >= 0 && newOffset + visibleMonths <= totalData) {
        chartOffset.value = newOffset
        await updateChart()
      } else {
        console.log(`範囲外のため移動をスキップ: newOffset=${newOffset}, visibleMonths=${visibleMonths}, totalData=${totalData}`)
      }
    }
    
    onMounted(() => {
      nextTick(() => {
        createChart()
      })
    })
    
    watch(() => props.data, (newData) => {
      if (newData && newData.labels && newData.datasets && !isUpdating.value) {
        updateChart()
      }
    }, { deep: true })
    
    // プライバシーモード変更時もチャートを再描画
    watch(() => props.isPrivacyMode, () => {
      if (props.data && props.data.labels && props.data.datasets && !isUpdating.value) {
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
      
      if (pieChartInstance.value) {
        try {
          pieChartInstance.value.destroy()
        } catch (error) {
          console.warn('Pie chart destroy error on unmount:', error)
        }
        pieChartInstance.value = null
      }
    })
    
    return {
      chartCanvas,
      chartWrapper,
      pieChartCanvas,
      chartLegend,
      canGoPrevious,
      canGoNext,
      chartPeriodText,
      shiftChart,
      isUpdating
    }
  }
}
</script>

<style lang="scss" scoped>
.expense-chart {
  .chart-controls {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 20px;
    margin-bottom: 15px;
    
    .nav-btn {
      background: #4CAF50;
      color: white;
      border: none;
      padding: 8px 12px;
      border-radius: 4px;
      cursor: pointer;
      font-size: 16px;
      transition: background 0.2s;
      
      &:hover:not(:disabled) {
        background: #45a049;
      }
      
      &:disabled {
        background: #ccc;
        cursor: not-allowed;
        color: #999;
        
        &.updating {
          background: #f0f0f0;
          opacity: 0.7;
          pointer-events: none;
        }
      }
    }
    
    .chart-period {
      font-weight: 600;
      color: #333;
      min-width: 200px;
      text-align: center;
    }
  }
  
  .chart-container {
    position: relative;
    margin: 0 auto 20px auto;
    max-width: 100%;
    padding: 0;
    
    .chart-wrapper {
      position: relative;
      width: 100%;
      
      canvas {
        display: block;
        width: 100% !important;
        height: auto !important;
      }
    }
  }
  
  .pie-chart-section {
    margin-top: 40px;
    background: #f8f9fa;
    border-radius: 10px;
    padding: 25px;
    
    .pie-chart-title {
      text-align: center;
      margin-bottom: 25px;
      color: #333;
      font-size: 1.3em;
      font-weight: 600;
    }
    
    .pie-chart-container {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 30px;
      align-items: center;
      
      canvas {
        display: block;
        max-width: 300px;
        max-height: 300px;
        margin: 0 auto;
      }
      
      .chart-legend {
        .legend-item {
          display: flex;
          align-items: center;
          margin-bottom: 12px;
          padding: 8px;
          background: white;
          border-radius: 6px;
          box-shadow: 0 1px 3px rgba(0,0,0,0.1);
          transition: background 0.2s ease;
          
          &:hover {
            background: #e9ecef;
          }
          
          .legend-color {
            width: 16px;
            height: 16px;
            border-radius: 3px;
            margin-right: 10px;
            flex-shrink: 0;
          }
          
          .legend-label {
            flex: 1;
            font-weight: 500;
            color: #333;
            font-size: 14px;
          }
          
          .legend-value {
            font-weight: 600;
            color: #666;
            font-size: 13px;
          }
        }
      }
    }
  }
}

// モバイル対応
@media (max-width: 768px) {
  .expense-chart {
    .chart-controls {
      gap: 10px;
      
      .chart-period {
        min-width: 150px;
        font-size: 14px;
      }
      
      .nav-btn {
        padding: 6px 10px;
        font-size: 14px;
      }
    }
    
    .pie-chart-section {
      padding: 20px;
      
      .pie-chart-container {
        grid-template-columns: 1fr;
        gap: 20px;
        
        canvas {
          max-width: 250px;
          max-height: 250px;
        }
        
        .chart-legend {
          .legend-item {
            margin-bottom: 8px;
            padding: 6px;
            
            .legend-label {
              font-size: 13px;
            }
            
            .legend-value {
              font-size: 12px;
            }
          }
        }
      }
    }
  }
}
</style>