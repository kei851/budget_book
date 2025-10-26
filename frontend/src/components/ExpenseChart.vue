<!-- Pugテンプレート構文を使用したHTML構造定義 -->
<template lang="pug">
// グラフ表示のメインコンテナ
.expense-chart
  // チャート操作コントロール（左右ボタンと期間表示）
  .chart-controls
    // 左矢印ボタン：前の期間へ移動
    button.nav-btn(:disabled="!canGoPrevious || isUpdating" @click="shiftChart(-1)") ←
    // 表示中の期間テキスト（例：2024/01 ～ 2024/12）
    span.chart-period {{ chartPeriodText }}
    // 右矢印ボタン：次の期間へ移動
    button.nav-btn(:disabled="!canGoNext || isUpdating" @click="shiftChart(1)") →
  // チャート描画エリア
  .chart-container
    // Chart.jsのcanvas要素を囲むラッパー
    .chart-wrapper(ref="chartWrapper")
      // Chart.jsで棒グラフを描画するcanvas要素
      canvas(ref="chartCanvas")
</template>

<script>
// Vue 3のComposition API機能をインポート
import { ref, onMounted, onBeforeUnmount, watch, nextTick } from 'vue'
// Chart.jsライブラリの必要なコンポーネントをインポート
import {
  Chart,              // Chart.jsのメインクラス
  CategoryScale,      // カテゴリ軸（X軸：月ラベル）
  LinearScale,        // 線形軸（Y軸：金額）
  BarElement,         // 棒グラフ要素
  Title,              // グラフタイトル
  Tooltip,            // ホバー時のツールチップ
  Legend              // 凡例
} from 'chart.js'

// Chart.js コンポーネントをグローバルに登録（使用前に必須）
Chart.register(
  CategoryScale,      // カテゴリ軸の登録
  LinearScale,        // 線形軸の登録
  BarElement,         // 棒グラフ要素の登録
  Title,              // タイトルの登録
  Tooltip,            // ツールチップの登録
  Legend              // 凡例の登録
)

// Vueコンポーネントの定義
export default {
  name: 'ExpenseChart',  // コンポーネント名
  // 親コンポーネントから受け取るプロパティ
  props: {
    // グラフデータ（labels配列とdatasets配列を含むオブジェクト）
    data: {
      type: Object,      // データ型：オブジェクト
      required: true     // 必須プロパティ
    },
    // プライバシーモードフラグ（金額を隠す）
    isPrivacyMode: {
      type: Boolean,     // データ型：真偽値
      default: false     // デフォルト値：false
    }
  },
  // 親コンポーネントに送信するイベント定義
  emits: ['navigation-state'],
  // Composition API のセットアップ関数
  setup(props, { emit }) {
    // DOM参照用のref（リアクティブな参照）
    const chartCanvas = ref(null)         // 棒グラフのcanvas要素への参照
    const chartWrapper = ref(null)        // チャートラッパー要素への参照
    const chartInstance = ref(null)       // Chart.jsインスタンスの保持
    const pieChartCanvas = ref(null)      // 円グラフのcanvas要素への参照
    const pieChartInstance = ref(null)    // 円グラフChart.jsインスタンスの保持
    const chartLegend = ref(null)         // カスタム凡例要素への参照

    // グラフ表示の状態管理
    const chartOffset = ref(0)            // 表示開始位置（配列インデックス）
    const visibleMonths = 12              // 一度に表示する月数（固定値）
    const isUpdating = ref(false)         // チャート更新中フラグ（二重更新防止用）
    
    // 初期表示で最新月が右端に来るようにオフセットを計算する関数
    const calculateInitialOffset = () => {
      // データが無い、またはvisibleMonths以下の場合はオフセット不要
      if (!props.data || !props.data.labels || props.data.labels.length <= visibleMonths) {
        return 0  // オフセット0（先頭から表示）
      }
      // 最新データが右端に来るように計算（全データ数 - 表示数）
      return props.data.labels.length - visibleMonths
    }

    // 現在のオフセット位置から表示すべきデータを抽出する関数
    const getVisibleData = () => {
      // データが無効な場合は空配列を返す
      if (!props.data || !props.data.labels) return { labels: [], datasets: [] }

      // 全データを取得
      const allLabels = props.data.labels          // 全ての月ラベル配列
      const allDatasets = props.data.datasets || [] // 全てのデータセット配列

      // 表示範囲のインデックスを計算
      const startIdx = chartOffset.value                           // 開始インデックス
      const endIdx = Math.min(startIdx + visibleMonths, allLabels.length)  // 終了インデックス

      // ラベルをスライス（部分抽出）
      const visibleLabels = allLabels.slice(startIdx, endIdx)
      // 各データセットのデータ配列も同じ範囲でスライス
      const visibleDatasets = allDatasets.map(dataset => ({
        ...dataset,                                 // データセットの他のプロパティはそのまま
        data: dataset.data.slice(startIdx, endIdx)  // データ配列のみスライス
      }))

      // 表示用データを返す
      return { labels: visibleLabels, datasets: visibleDatasets }
    }
    
    // ナビゲーションボタン（左右矢印）の有効/無効を管理するref
    const canGoPrevious = ref(false)  // 左矢印（前へ戻る）の有効フラグ
    const canGoNext = ref(false)      // 右矢印（次へ進む）の有効フラグ

    // ナビゲーション状態を更新し、親コンポーネントに通知する関数
    const updateNavigationState = () => {
      // データが無効な場合は全てのナビゲーションを無効化
      if (!props.data || !props.data.labels || !props.data.datasets) {
        canGoPrevious.value = false  // 左矢印を無効化
        canGoNext.value = false      // 右矢印を無効化
        // 親コンポーネントに無効状態を通知
        emit('navigation-state', {
          canGoPrevious: false,      // 前へ戻れない
          canGoNext: false,          // 次へ進めない
          totalMonths: 0,            // 総月数0
          currentOffset: 0,          // 現在位置0
          availableMonths: []        // 利用可能な月なし
        })
        return  // 処理終了
      }

      // 正しい判定ロジック
      // 左矢印: オフセットが0より大きい = 前のデータが存在する = 戻れる
      canGoPrevious.value = chartOffset.value > 0

      // 右矢印: 現在の表示終了位置が全データより小さい = 後ろのデータが存在する = 進める
      canGoNext.value = (chartOffset.value + visibleMonths) < props.data.labels.length

      // ナビゲーション状態を親コンポーネントに通知（イベント送信）
      emit('navigation-state', {
        canGoPrevious: canGoPrevious.value,           // 前へ戻れるか
        canGoNext: canGoNext.value,                   // 次へ進めるか
        totalMonths: props.data.labels.length,        // 総月数
        currentOffset: chartOffset.value,             // 現在のオフセット位置
        availableMonths: props.data.labels || []      // 全ての月ラベル配列
      })
    }
    
    // 表示期間のテキスト（例：「2024/01 ～ 2024/12」）を保持するref
    const chartPeriodText = ref('')

    // 表示期間テキストを更新する関数
    const updatePeriodText = () => {
      // データが無効な場合は空文字列にする
      if (!props.data || !props.data.labels || props.data.labels.length === 0) {
        chartPeriodText.value = ''  // 空文字列を設定
        return  // 処理終了
      }

      // 表示開始月のラベルを取得
      const startLabel = props.data.labels[chartOffset.value] || ''
      // 表示終了月のインデックスを計算（配列範囲外にならないよう制限）
      const endIdx = Math.min(chartOffset.value + visibleMonths - 1, props.data.labels.length - 1)
      // 表示終了月のラベルを取得
      const endLabel = props.data.labels[endIdx] || ''

      // 開始月と終了月が同じ場合（1ヶ月のみ表示）
      if (startLabel === endLabel) {
        chartPeriodText.value = startLabel  // 単一の月ラベルのみ表示
      } else {
        // 複数月表示の場合は「開始月 ～ 終了月」形式
        chartPeriodText.value = `${startLabel} ～ ${endLabel}`
      }
    }

    // Chart.jsの棒グラフを作成する関数
    const createChart = () => {
      // canvas要素またはデータが無い場合は作成をスキップ
      if (!chartCanvas.value || !props.data) {
        console.warn('Chart creation skipped: canvas or data not available')  // 警告ログ出力
        return  // 処理中断
      }

      // canvas要素が正しくDOMに接続されているかチェック
      if (!chartCanvas.value.isConnected) {
        console.warn('Chart creation skipped: canvas not connected to DOM')  // 警告ログ出力
        return  // 処理中断
      }

      // 初回作成時は最新月が右端に来るようにオフセットを設定
      if (chartOffset.value === 0 && props.data.labels && props.data.labels.length > visibleMonths) {
        chartOffset.value = calculateInitialOffset()  // 初期オフセットを計算して設定
      }

      try {
        // 現在表示すべきデータを取得
        const visibleData = getVisibleData()
        // ラベルが空の場合は作成をスキップ
        if (!visibleData.labels.length) return

        // データセットのバリデーション：データセット配列が存在し、空でないことを確認
        if (!visibleData.datasets || visibleData.datasets.length === 0) {
          console.warn('Chart creation skipped: no valid datasets')  // 警告ログ出力
          return  // 処理中断
        }

        // 各データセットのデータ配列をバリデーション
        const validDatasets = visibleData.datasets.filter(dataset => {
          return dataset &&                                       // datasetが存在する
                 Array.isArray(dataset.data) &&                   // dataが配列である
                 dataset.data.length > 0 &&                       // データが空でない
                 dataset.data.every(val => typeof val === 'number' && !isNaN(val))  // 全て有効な数値
        })

        // バリデーション後に有効なデータセットが無い場合はスキップ
        if (validDatasets.length === 0) {
          console.warn('Chart creation skipped: no valid datasets after validation')  // 警告ログ出力
          return  // 処理中断
        }

        // canvas要素から2D描画コンテキストを取得
        const ctx = chartCanvas.value.getContext('2d')
        // コンテキスト取得に失敗した場合はスキップ
        if (!ctx) {
          console.warn('Chart creation skipped: cannot get 2d context')  // 警告ログ出力
          return  // 処理中断
        }
      // Chart.jsインスタンスを生成（棒グラフ）
      chartInstance.value = new Chart(ctx, {
        type: 'bar',  // グラフタイプ：棒グラフ
        // グラフに表示するデータ
        data: {
          labels: visibleData.labels,   // X軸のラベル（月）
          datasets: validDatasets       // データセット配列（カテゴリ別の金額）
        },
        // グラフの詳細設定
        options: {
          responsive: true,              // レスポンシブ対応（画面サイズに応じて調整）
          maintainAspectRatio: true,     // アスペクト比を維持
          aspectRatio: 2,                // アスペクト比 2:1（横長）
          animation: false,              // アニメーションを無効化（パフォーマンス向上）
          // トランジション設定
          transitions: {
            active: {
              animation: {
                duration: 0            // アクティブ時のアニメーション時間を0に設定
              }
            }
          },
          // レイアウト設定（グラフのパディング）
          layout: {
            padding: {
              left: 110,  // 左側のパディング（Y軸の幅に余裕を持たせて固定）
              right: 20,  // 右側のパディング
              top: 10,    // 上部のパディング
              bottom: 10  // 下部のパディング
            }
          },
          // 軸の設定
          scales: {
            // X軸（横軸）の設定
            x: {
              stacked: true,          // 積み上げグラフを有効化
              // 目盛りラベル設定
              ticks: {
                maxRotation: 45       // ラベルの最大回転角度（45度まで傾ける）
              },
              // グリッド線設定
              grid: {
                offset: false         // グリッド線のオフセットを無効化
              },
              categoryPercentage: 1.0, // カテゴリ幅の割合（100%）
              barPercentage: 0.9       // 棒の幅の割合（90%）
            },
            // Y軸（縦軸）の設定
            y: {
              stacked: true,          // 積み上げグラフを有効化
              beginAtZero: true,      // Y軸を0から開始
              // 目盛りラベル設定
              ticks: {
                // ラベルの表示内容をカスタマイズする関数
                callback: function(value) {
                  if (props.isPrivacyMode) {
                    // プライバシーモード時は金額を隠す（固定桁数で統一表示）
                    return '¥*******'
                  } else {
                    // 通常モード時：金額を3桁区切りで表示
                    const formattedValue = '¥' + value.toLocaleString()
                    return formattedValue.padStart(8, ' ') // 最小8桁で右揃え（軸幅の安定化）
                  }
                },
                minWidth: 100,        // 軸の最小幅を設定（軸幅の固定化）
                padding: 10           // ラベルのパディング（文字数統一のため右揃え）
              },
              // グリッド線設定
              grid: {
                offset: false         // グリッド線のオフセットを無効化
              },
              position: 'left',       // Y軸を左側に配置
              // Y軸の幅を固定するためのフック関数
              afterFit: function(scale) {
                scale.width = 100;    // 固定幅100pxを設定（ナビゲーション時の軸ジャンプ防止）
              }
            }
          },
          // プラグイン設定
          plugins: {
            // 凡例（legend）の設定
            legend: {
              display: true,         // 凡例を表示
              position: 'bottom',    // 凡例をグラフ下部に配置
              // 凡例ラベルの設定
              labels: {
                usePointStyle: true, // ポイントスタイル（円形）を使用
                padding: 5,          // ラベル間のパディング
                font: {
                  size: 11           // フォントサイズ 11px
                }
              }
            },
            // ツールチップ（ホバー時のポップアップ）の設定
            tooltip: {
              // ツールチップ表示内容のカスタマイズ関数群
              callbacks: {
                // 各データセット行のラベル表示をカスタマイズ
                label: function(context) {
                  if (props.isPrivacyMode) {
                    // プライバシーモード時：金額を隠す
                    return context.dataset.label + ': ¥*******'
                  } else {
                    // 通常モード時：「カテゴリ名: ¥金額」形式で表示
                    return context.dataset.label + ': ¥' + context.parsed.y.toLocaleString()
                  }
                },
                // ツールチップのフッター（合計金額）をカスタマイズ
                footer: function(tooltipItems) {
                  if (props.isPrivacyMode) {
                    // プライバシーモード時：合計金額を隠す
                    return '合計: ¥*******'
                  } else {
                    // 通常モード時：全カテゴリの合計を計算して表示
                    let total = 0
                    tooltipItems.forEach(function(tooltipItem) {
                      total += tooltipItem.parsed.y  // 各カテゴリの金額を加算
                    })
                    return '合計: ¥' + total.toLocaleString()  // 「合計: ¥金額」形式
                  }
                }
              }
            }
          },
          // インタラクション（マウス操作）の設定
          interaction: {
            mode: 'index',      // インデックスモード（同じX軸位置の全データを対象）
            intersect: false    // 交差不要（マウスが要素上になくても反応）
          }
        }
      })

      // グラフ作成後の初期化処理
      updateNavigationState()  // ナビゲーションボタンの有効/無効状態を更新
      updatePeriodText()       // 表示期間テキストを更新

      // パイチャート（円グラフ）も作成
      createPieChart()

      } catch (error) {
        // エラーが発生した場合はコンソールにエラー情報を出力
        console.error('Chart creation error:', error)
      }
    }
    
    // パイチャート（円グラフ）を作成する関数
    const createPieChart = () => {
      // canvas要素またはデータが無い場合は作成をスキップ
      if (!pieChartCanvas.value || !props.data) {
        console.warn('Pie chart creation skipped: canvas or data not available')  // 警告ログ
        return  // 処理中断
      }

      // canvas要素が正しくDOMに接続されているかチェック
      if (!pieChartCanvas.value.isConnected) {
        console.warn('Pie chart creation skipped: canvas not connected to DOM')  // 警告ログ
        return  // 処理中断
      }

      try {
        // 現在表示中のデータから各カテゴリの合計値を計算
        const visibleData = getVisibleData()  // 表示中のデータを取得
        // データセットが無効な場合はスキップ
        if (!visibleData.datasets || visibleData.datasets.length === 0) {
          console.warn('Pie chart creation skipped: no valid datasets')  // 警告ログ
          return  // 処理中断
        }

        // 各カテゴリの合計額を計算（円グラフ用のデータ整形）
        const categoryTotals = visibleData.datasets.map(dataset => {
          // データ配列の全要素を合計（reduce関数で累積加算）
          const total = dataset.data.reduce((sum, value) => sum + value, 0)
          return {
            label: dataset.label,                // カテゴリ名
            value: total,                        // 合計金額
            color: dataset.backgroundColor       // カテゴリの色
          }
        }).filter(item => item.value > 0)  // 0円のカテゴリは除外（円グラフに表示しない）

        // 全てのカテゴリが0円の場合はスキップ
        if (categoryTotals.length === 0) {
          console.warn('Pie chart creation skipped: no data with values > 0')  // 警告ログ
          return  // 処理中断
        }

        // canvas要素から2D描画コンテキストを取得
        const pieCtx = pieChartCanvas.value.getContext('2d')
        // コンテキスト取得に失敗した場合はスキップ
        if (!pieCtx) {
          console.warn('Pie chart creation skipped: cannot get 2d context')  // 警告ログ
          return  // 処理中断
        }
        // Chart.jsインスタンスを生成（ドーナツチャート/円グラフ）
        pieChartInstance.value = new Chart(pieCtx, {
          type: 'doughnut',  // グラフタイプ：ドーナツチャート（中心が空いた円グラフ）
          // グラフに表示するデータ
          data: {
            labels: categoryTotals.map(item => item.label),  // ラベル配列（カテゴリ名）
            datasets: [{
              data: categoryTotals.map(item => item.value),           // データ配列（金額）
              backgroundColor: categoryTotals.map(item => item.color), // 背景色配列（カテゴリ色）
              borderWidth: 0,            // 通常時の境界線幅（なし）
              hoverBorderWidth: 2,       // ホバー時の境界線幅
              hoverBorderColor: '#fff'   // ホバー時の境界線色（白）
            }]
          },
          // グラフの詳細設定
          options: {
            responsive: true,           // レスポンシブ対応
            maintainAspectRatio: true,  // アスペクト比を維持
            aspectRatio: 1,             // アスペクト比 1:1（正方形）
            animation: false,           // アニメーションを無効化
            cutout: '50%',              // 中心の切り抜き（50% = ドーナツ型）
            // プラグイン設定
            plugins: {
              legend: {
                display: false  // 標準凡例を非表示（カスタム凡例を使用するため）
              },
              // ツールチップ設定
              tooltip: {
                callbacks: {
                  // ラベル表示をカスタマイズ
                  label: function(context) {
                    if (props.isPrivacyMode) {
                      // プライバシーモード時：金額を隠す
                      return context.label + ': ¥*******'
                    } else {
                      // 通常モード時：「カテゴリ名: ¥金額」形式
                      return context.label + ': ¥' + context.parsed.toLocaleString()
                    }
                  }
                }
              }
            }
          }
        })

        // カスタム凡例を生成（円グラフの横に表示する詳細リスト）
        generateCustomLegend(categoryTotals)

      } catch (error) {
        // エラーが発生した場合はコンソールにエラー情報を出力
        console.error('Pie chart creation error:', error)
      }
    }
    
    // カスタム凡例を生成する関数（円グラフ横に表示するカテゴリ別の詳細リスト）
    const generateCustomLegend = (categoryTotals) => {
      const legendContainer = chartLegend.value  // 凡例コンテナ要素を取得
      if (!legendContainer) return  // 要素が無い場合は処理中断

      // 既存の凡例をクリア（前回の内容を削除）
      legendContainer.innerHTML = ''

      // 各カテゴリの凡例アイテムを生成
      categoryTotals.forEach(item => {
        // 凡例アイテムのコンテナdivを作成
        const legendItem = document.createElement('div')
        legendItem.className = 'legend-item'  // CSSクラス設定

        // カラーボックス（カテゴリ色の四角）を作成
        const colorBox = document.createElement('div')
        colorBox.className = 'legend-color'           // CSSクラス設定
        colorBox.style.backgroundColor = item.color   // 背景色を設定

        // カテゴリ名のラベルを作成
        const labelText = document.createElement('span')
        labelText.className = 'legend-label'    // CSSクラス設定
        labelText.textContent = item.label      // テキスト内容を設定

        // 金額のラベルを作成
        const valueText = document.createElement('span')
        valueText.className = 'legend-value'    // CSSクラス設定
        if (props.isPrivacyMode) {
          // プライバシーモード時：金額を隠す
          valueText.textContent = '¥*******'
        } else {
          // 通常モード時：金額を3桁区切りで表示
          valueText.textContent = '¥' + item.value.toLocaleString()
        }

        // DOM構造を組み立て（カラーボックス + ラベル + 金額）
        legendItem.appendChild(colorBox)
        legendItem.appendChild(labelText)
        legendItem.appendChild(valueText)
        // コンテナに追加
        legendContainer.appendChild(legendItem)
      })
    }
    
    // チャートを更新する関数（既存チャートを破棄して再作成）
    const updateChart = async () => {
      if (isUpdating.value) return  // 既に更新中の場合は処理を中断（二重更新防止）

      isUpdating.value = true  // 更新中フラグをON

      try {
        // 既存の棒グラフインスタンスが存在する場合は破棄
        if (chartInstance.value) {
          try {
            chartInstance.value.destroy()  // Chart.jsインスタンスを破棄
          } catch (error) {
            console.warn('Chart destroy error:', error)  // 破棄エラーは警告のみ
          }
          chartInstance.value = null  // 参照をクリア
        }

        // 既存の円グラフインスタンスが存在する場合は破棄
        if (pieChartInstance.value) {
          try {
            pieChartInstance.value.destroy()  // Chart.jsインスタンスを破棄
          } catch (error) {
            console.warn('Pie chart destroy error:', error)  // 破棄エラーは警告のみ
          }
          pieChartInstance.value = null  // 参照をクリア
        }

        // 新しいチャートを作成（DOM更新を待ってから実行）
        await nextTick()  // Vue.jsのDOM更新を待機
        createChart()     // 新しいチャートを作成
      } catch (error) {
        // エラーが発生した場合はコンソールにエラー情報を出力
        console.error('Chart update error:', error)
      } finally {
        // Chart.jsが完全に安定してから次の処理を許可（500ms遅延）
        setTimeout(() => {
          isUpdating.value = false  // 更新中フラグをOFF
        }, 500)
      }
    }

    // 矢印ボタンでグラフをシフトする関数（左右移動）
    const shiftChart = async (direction) => {
      if (isUpdating.value) return  // 更新中は処理をスキップ（連打防止）

      // 新しいオフセット位置を計算（direction: -1=左, +1=右）
      const newOffset = chartOffset.value + direction
      // 総データ数を取得
      const totalData = props.data?.labels?.length || 0

      // 範囲チェック：0以上、かつ表示範囲が全データ内に収まる
      if (newOffset >= 0 && newOffset + visibleMonths <= totalData) {
        chartOffset.value = newOffset  // オフセットを更新
        await updateChart()             // チャートを再描画
      } else {
        // 範囲外の場合は移動をスキップ（ログ出力）
        console.log(`範囲外のため移動をスキップ: newOffset=${newOffset}, visibleMonths=${visibleMonths}, totalData=${totalData}`)
      }
    }
    
    // コンポーネントマウント時のライフサイクルフック
    onMounted(() => {
      nextTick(() => {
        createChart()  // DOM描画完了後にチャートを作成
      })
    })

    // props.dataの変更を監視（データ更新時にチャートを再描画）
    watch(() => props.data, (newData) => {
      // データが有効かつ更新中でない場合のみチャートを更新
      if (newData && newData.labels && newData.datasets && !isUpdating.value) {
        updateChart()  // チャートを再描画
      }
    }, { deep: true })  // オブジェクトの深い階層まで監視

    // プライバシーモードの変更を監視（モード切替時にチャートを再描画）
    watch(() => props.isPrivacyMode, () => {
      // データが有効かつ更新中でない場合のみチャートを更新
      if (props.data && props.data.labels && props.data.datasets && !isUpdating.value) {
        updateChart()  // チャートを再描画（金額表示/非表示の切替）
      }
    })

    // コンポーネントアンマウント前のライフサイクルフック（クリーンアップ処理）
    onBeforeUnmount(() => {
      // 棒グラフインスタンスの破棄
      if (chartInstance.value) {
        try {
          chartInstance.value.destroy()  // Chart.jsインスタンスを破棄
        } catch (error) {
          console.warn('Chart destroy error on unmount:', error)  // エラーは警告のみ
        }
        chartInstance.value = null  // 参照をクリア
      }

      // 円グラフインスタンスの破棄
      if (pieChartInstance.value) {
        try {
          pieChartInstance.value.destroy()  // Chart.jsインスタンスを破棄
        } catch (error) {
          console.warn('Pie chart destroy error on unmount:', error)  // エラーは警告のみ
        }
        pieChartInstance.value = null  // 参照をクリア
      }
    })

    // テンプレートで使用する変数・関数を返す
    return {
      chartCanvas,       // 棒グラフcanvas要素への参照
      chartWrapper,      // チャートラッパー要素への参照
      pieChartCanvas,    // 円グラフcanvas要素への参照
      chartLegend,       // カスタム凡例要素への参照
      canGoPrevious,     // 左矢印ボタンの有効/無効フラグ
      canGoNext,         // 右矢印ボタンの有効/無効フラグ
      chartPeriodText,   // 表示期間テキスト
      shiftChart,        // グラフ移動関数
      isUpdating         // 更新中フラグ
    }
  }
}
</script>

<!-- SCSSスタイル（scopedで他コンポーネントに影響しない） -->
<style lang="scss" scoped>
// グラフ全体のコンテナ
.expense-chart {
  // グラフ操作コントロール（左右矢印ボタンと期間表示）
  .chart-controls {
    display: flex;           // フレックスボックスレイアウト
    align-items: center;     // 垂直方向中央揃え
    justify-content: center; // 水平方向中央揃え
    gap: 20px;               // 要素間のスペース
    margin-bottom: 15px;     // 下部マージン

    // ナビゲーションボタン（左右矢印）
    .nav-btn {
      background: #4CAF50;   // 背景色（緑）
      color: white;          // 文字色（白）
      border: none;          // 枠線なし
      padding: 8px 12px;     // 内側の余白
      border-radius: 4px;    // 角の丸み
      cursor: pointer;       // カーソルをポインターに
      font-size: 16px;       // フォントサイズ
      transition: background 0.2s;  // 背景色の変化をアニメーション

      // ホバー時（無効でない場合のみ）
      &:hover:not(:disabled) {
        background: #45a049;  // 少し暗い緑に変化
      }

      // 無効状態（ボタンが押せない状態）
      &:disabled {
        background: #ccc;      // 背景色グレー
        cursor: not-allowed;   // カーソルを禁止マークに
        color: #999;           // 文字色を薄いグレーに

        // 更新中の状態
        &.updating {
          background: #f0f0f0;    // より薄いグレー
          opacity: 0.7;           // 透明度を下げる
          pointer-events: none;   // クリックイベントを無効化
        }
      }
    }

    // 表示期間テキスト（中央の「2024/01 ～ 2024/12」部分）
    .chart-period {
      font-weight: 600;    // フォント太字
      color: #333;         // 文字色（濃いグレー）
      min-width: 200px;    // 最小幅（レイアウト安定化）
      text-align: center;  // テキスト中央揃え
    }
  }
  // グラフ描画コンテナ
  .chart-container {
    position: relative;         // 相対位置指定
    margin: 0 auto 20px auto;   // 中央揃え、下部マージン
    max-width: 100%;            // 最大幅100%（レスポンシブ対応）
    padding: 0;                 // パディングなし

    // Chart.jsのcanvasを囲むラッパー
    .chart-wrapper {
      position: relative;  // 相対位置指定
      width: 100%;         // 幅100%

      // Canvas要素
      canvas {
        display: block;           // ブロック要素として表示
        width: 100% !important;   // 幅100%（強制）
        height: auto !important;  // 高さ自動調整（強制）
      }
    }
  }

  // 円グラフセクション
  .pie-chart-section {
    margin-top: 40px;       // 上部マージン
    background: #f8f9fa;    // 背景色（薄いグレー）
    border-radius: 10px;    // 角の丸み
    padding: 25px;          // 内側の余白

    // 円グラフのタイトル
    .pie-chart-title {
      text-align: center;   // テキスト中央揃え
      margin-bottom: 25px;  // 下部マージン
      color: #333;          // 文字色（濃いグレー）
      font-size: 1.3em;     // フォントサイズ
      font-weight: 600;     // フォント太字
    }

    // 円グラフと凡例のコンテナ
    .pie-chart-container {
      display: grid;                    // グリッドレイアウト
      grid-template-columns: 1fr 1fr;   // 2カラム（円グラフ | 凡例）
      gap: 30px;                        // カラム間のスペース
      align-items: center;              // 垂直方向中央揃え

      // 円グラフのcanvas要素
      canvas {
        display: block;       // ブロック要素として表示
        max-width: 300px;     // 最大幅300px
        max-height: 300px;    // 最大高さ300px
        margin: 0 auto;       // 中央揃え
      }

      // カスタム凡例コンテナ
      .chart-legend {
        // 凡例の各アイテム
        .legend-item {
          display: flex;                          // フレックスボックスレイアウト
          align-items: center;                    // 垂直方向中央揃え
          margin-bottom: 12px;                    // 下部マージン
          padding: 8px;                           // 内側の余白
          background: white;                      // 背景色（白）
          border-radius: 6px;                     // 角の丸み
          box-shadow: 0 1px 3px rgba(0,0,0,0.1); // 影効果
          transition: background 0.2s ease;       // 背景色の変化をアニメーション

          // ホバー時
          &:hover {
            background: #e9ecef;  // 背景色を薄いグレーに変化
          }

          // カラーボックス（カテゴリ色の四角）
          .legend-color {
            width: 16px;         // 幅16px
            height: 16px;        // 高さ16px
            border-radius: 3px;  // 角の丸み
            margin-right: 10px;  // 右側マージン
            flex-shrink: 0;      // 縮小を防止
          }

          // カテゴリ名ラベル
          .legend-label {
            flex: 1;           // 残りスペースを占有
            font-weight: 500;  // フォント中太字
            color: #333;       // 文字色（濃いグレー）
            font-size: 14px;   // フォントサイズ
          }

          // 金額ラベル
          .legend-value {
            font-weight: 600;  // フォント太字
            color: #666;       // 文字色（中間グレー）
            font-size: 13px;   // フォントサイズ
          }
        }
      }
    }
  }
}

// モバイル対応（画面幅768px以下）
@media (max-width: 768px) {
  .expense-chart {
    // グラフコントロール部分のモバイル対応
    .chart-controls {
      gap: 10px;  // 要素間のスペースを狭く

      // 表示期間テキスト
      .chart-period {
        min-width: 150px;  // 最小幅を縮小
        font-size: 14px;   // フォントサイズを縮小
      }

      // ナビゲーションボタン
      .nav-btn {
        padding: 6px 10px;  // パディングを縮小
        font-size: 14px;    // フォントサイズを縮小
      }
    }

    // 円グラフセクションのモバイル対応
    .pie-chart-section {
      padding: 20px;  // パディングを縮小

      // 円グラフと凡例のコンテナ
      .pie-chart-container {
        grid-template-columns: 1fr;  // 1カラム（縦並び）に変更
        gap: 20px;                   // スペースを縮小

        // 円グラフcanvas
        canvas {
          max-width: 250px;   // 最大幅を縮小
          max-height: 250px;  // 最大高さを縮小
        }

        // カスタム凡例
        .chart-legend {
          // 凡例の各アイテム
          .legend-item {
            margin-bottom: 8px;  // 下部マージンを縮小
            padding: 6px;        // パディングを縮小

            // カテゴリ名ラベル
            .legend-label {
              font-size: 13px;  // フォントサイズを縮小
            }

            // 金額ラベル
            .legend-value {
              font-size: 12px;  // フォントサイズを縮小
            }
          }
        }
      }
    }
  }
}
</style>