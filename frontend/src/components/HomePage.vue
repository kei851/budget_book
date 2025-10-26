<template lang="pug">
//- メインのホームページコンテナ
.home-page
  //- ファイルアップロードと対応形式を表示するコンテナ
  .upload-container
    //- ファイルアップロード部分
    .upload-section
      //- アップロードアイコン
      .upload-icon 📁
      //- アップロード説明テキスト
      .upload-text 右の対応済みの形式のファイルをアップロード
      //- ファイルアップロードコンポーネント
      FileUpload(
        @file-uploaded="handleFileUpload"
        @folder-uploaded="handleFolderUpload"
        :loading="loading"
      )

    //- 対応ファイル形式テーブル部分
    .format-table-section
      //- セクションタイトル
      h3 対応ファイル形式
      //- 対応形式テーブル
      table.format-table
        //- テーブルヘッダー
        thead
          //- ヘッダー行
          tr
            //- 取引媒体カラム
            th 取引媒体
            //- 形式カラム
            th 形式
            //- 対応状況カラム
            th 対応状況
        //- テーブルボディ
        tbody
          //- 楽天カード行
          tr
            //- 楽天カード名
            td 楽天カード
            //- CSVファイル形式
            td CSV
            //- 対応状況セル
            td
              //- 対応済みステータス
              span.status.supported ✓ 対応
          //- 楽天銀行行
          tr
            //- 楽天銀行名
            td 楽天銀行
            //- CSVファイル形式
            td CSV
            //- 対応状況セル
            td
              //- 予定ステータス
              span.status.planned 予定
          //- エポスカード行
          tr
            //- エポスカード名
            td エポスカード
            //- CSVファイル形式
            td CSV
            //- 対応状況セル
            td
              //- 対応済みステータス
              span.status.supported ✓ 対応
          //- PayPay行
          tr
            //- PayPay名
            td PayPay
            //- CSVファイル形式
            td CSV
            //- 対応状況セル
            td
              //- 予定ステータス
              span.status.planned 予定


  //- グラフとサマリーを表示するセクション
  .chart-section
    //- グラフヘッダー
    .chart-header
      //- グラフタイトル
      .chart-title 月毎支出グラフ（12ヶ月）

    //- 支出グラフコンポーネント
    ExpenseChart(
      :data="chartData"
      :isPrivacyMode="isPrivacyMode"
      @navigation-state="handleNavigationState"
    )

    //- サマリーカードコンポーネント
    SummaryCards(:summary="summaryData" :isPrivacyMode="isPrivacyMode")
</template>

<script>
// Vue 3のComposition APIとリアクティブな機能をインポート
import { ref, reactive, onMounted } from 'vue'
// ファイルアップロードコンポーネントをインポート
import FileUpload from './FileUpload.vue'
// 支出グラフコンポーネントをインポート
import ExpenseChart from './ExpenseChart.vue'
// サマリーカードコンポーネントをインポート
import SummaryCards from './SummaryCards.vue'
// API通信サービスをインポート
import apiService from '../services/api.js'

export default {
  // コンポーネント名を定義
  name: 'HomePage',
  // 使用するコンポーネントを登録
  components: {
    FileUpload,
    ExpenseChart,
    SummaryCards
  },
  // 親コンポーネントから受け取るプロパティを定義
  props: {
    // プライバシーモードのON/OFF状態
    isPrivacyMode: {
      type: Boolean,
      default: false
    },
    // チャートナビゲーション状態
    chartNavigationState: {
      type: Object,
      default: () => ({
        canGoPrevious: false,
        canGoNext: false,
        totalMonths: 0,
        currentOffset: 0,
        availableMonths: []
      })
    }
  },
  // 親コンポーネントに送信するイベントを定義
  emits: ['navigate', 'chart-navigation-updated'],
  // Composition APIのセットアップ関数
  setup(props, { emit }) {
    // ローディング状態のリアクティブ変数
    const loading = ref(false)
    // アップロード成功状態のリアクティブ変数
    const uploadSuccess = ref(false)

    // チャートデータのリアクティブな変数
    const chartData = ref({
      labels: [],
      datasets: []
    })

    // チャートナビゲーション状態のリアクティブな変数
    const chartNavigationState = ref({
      canGoPrevious: false,
      canGoNext: false,
      totalMonths: 0,
      currentOffset: 0,
      availableMonths: []
    })

    // サマリーデータのリアクティブなオブジェクト
    const summaryData = reactive({
      thisMonth: 0,
      monthlyAverage: 0,
      maxMonth: 0,
      dataCount: 0
    })

    // APIからデータを読み込む非同期関数
    const loadData = async () => {
      try {
        // 月次データを取得
        const monthlyData = await apiService.getMonthlyData()
        // チャートデータを別途APIから取得して更新
        await updateChartData()
        // サマリーデータを更新
        updateSummaryData(monthlyData)
      } catch (error) {
        // エラーログを出力
        console.error('データ読み込みエラー:', error)
        // データがない場合は空のグラフを表示
        chartData.value = {
          labels: [],
          datasets: []
        }
      }
    }

    // チャートデータを更新する非同期関数
    const updateChartData = async () => {
      try {
        // 分析データを取得
        const analyticsData = await apiService.getAnalyticsData()

        // カテゴリ統計がない場合は空のチャートデータを設定
        if (!analyticsData.category_stats || analyticsData.category_stats.length === 0) {
          chartData.value = {
            labels: [],
            datasets: []
          }
          return
        }

        // 全ての月データを収集するためのSet
        const allMonths = new Set()
        // 各カテゴリの月次データから月を収集
        analyticsData.category_stats.forEach(category => {
          if (category.monthly_data) {
            Object.keys(category.monthly_data).forEach(month => {
              allMonths.add(month)
            })
          }
        })

        // 月をソートして全期間のデータを使用
        const sortedMonths = Array.from(allMonths).sort()

        // 各カテゴリのデータセットを作成
        const datasets = analyticsData.category_stats.map(category => ({
          label: category.name,
          data: sortedMonths.map(month => {
            const value = category.monthly_data[month]
            return value ? Math.round(parseFloat(value)) : 0
          }),
          backgroundColor: category.color,
          borderWidth: 0
        }))

        // チャートデータを設定
        chartData.value = {
          labels: sortedMonths.map(monthKey => {
            const [year, month] = monthKey.split('-')
            return `${year}/${month}`
          }),
          // 0より大きい値を含むデータセットのみフィルタリング
          datasets: datasets.filter(dataset =>
            dataset.data.some(val => val > 0)
          )
        }

      } catch (error) {
        // エラーログを出力
        console.error('チャートデータ更新エラー:', error)
        // エラー時は空のチャートデータを設定
        chartData.value = {
          labels: [],
          datasets: []
        }
      }
    }

    // サマリーデータを更新する関数
    const updateSummaryData = (data) => {
      // 現在の月と年を取得
      const currentMonth = new Date().getMonth() + 1
      const currentYear = new Date().getFullYear()
      // 現在月のキーを作成
      const currentMonthKey = `${currentYear}-${currentMonth.toString().padStart(2, '0')}-01`

      // 今月の支出を設定
      summaryData.thisMonth = data.monthly_totals[currentMonthKey]
        ? Math.round(parseFloat(data.monthly_totals[currentMonthKey])) : 0

      // 月次データから有効な値のみを抽出
      const monthlyValues = Object.values(data.monthly_totals)
        .map(val => parseFloat(val))
        .filter(val => !isNaN(val) && val > 0)

      // 月平均支出を計算
      summaryData.monthlyAverage = monthlyValues.length > 0
        ? Math.round(monthlyValues.reduce((a, b) => a + b, 0) / monthlyValues.length)
        : 0
      // 最大月支出を設定
      summaryData.maxMonth = monthlyValues.length > 0 ? Math.round(Math.max(...monthlyValues)) : 0
      // データ件数を設定
      summaryData.dataCount = data.transaction_count || 0
    }

    // ファイルアップロード処理の非同期関数
    const handleFileUpload = async (file) => {
      // ローディング状態を開始
      loading.value = true
      // アップロード成功状態をリセット
      uploadSuccess.value = false

      try {
        // アップロード開始ログ
        console.log('ファイルアップロード開始:', file.name)

        // CSVファイルをアップロード（既存データは保持、重複チェックあり）
        const result = await apiService.uploadCsv(file, false)
        // アップロード完了ログ
        console.log('アップロード完了:', result)

        // インポートされたデータが1件以上ある場合
        if (result.imported_count > 0) {
          // アップロード成功状態を設定
          uploadSuccess.value = true
          // 成功メッセージを表示
          alert(`${result.imported_count}件のデータを正常にインポートしました！`)

          // データを再読み込み
          await loadData()
        } else {
          // データがない場合の警告メッセージ
          alert('インポートできるデータが見つかりませんでした。')
        }

        // エラーがある場合は警告ログを出力
        if (result.errors && result.errors.length > 0) {
          console.warn('インポート時のエラー:', result.errors)
        }

      } catch (error) {
        // エラーログとアラートを表示
        console.error('アップロードエラー:', error)
        alert(`アップロードに失敗しました: ${error.message}`)
      } finally {
        // ローディング状態を終了
        loading.value = false
      }
    }

    // フォルダーアップロード処理の非同期関数
    const handleFolderUpload = async (data) => {
      // フォルダーアップロード開始ログ
      console.log('フォルダーアップロード開始:', data.files.length, '個のファイル')

      // ローディング状態を開始
      loading.value = true
      // ファイル配列を取得
      const files = data.files
      // アップロード進捗オブジェクトを取得
      const uploadProgress = data.uploadProgress
      // 結果配列を初期化
      const results = []

      // 各ファイルを順次処理
      for (let i = 0; i < files.length; i++) {
        const file = files[i]
        // 現在の進捗を更新
        uploadProgress.current = i + 1

        try {
          // ファイル処理ログ
          console.log(`ファイル ${i + 1}/${files.length} 処理中: ${file.name}`)

          // 最初のファイルのみ既存データを削除、残りは追加
          const clearExisting = i === 0
          // CSVファイルをアップロード
          const result = await apiService.uploadCsv(file, clearExisting)
          // 完了ログ
          console.log(`${file.name} 完了:`, result)
          console.log('result.imported_count:', result.imported_count)

          // 成功結果を配列に追加
          results.push({
            file: file.name,
            status: 'success',
            importedCount: result.imported_count || 0
          })

          // 300ms待機してサーバー負荷を軽減
          await new Promise(resolve => setTimeout(resolve, 300))

        } catch (error) {
          // エラーログ
          console.error(`${file.name} の処理でエラー:`, error)
          // エラー結果を配列に追加
          results.push({
            file: file.name,
            status: 'error',
            error: error.message
          })
        }
      }

      // 進捗をリセット
      uploadProgress.current = 0
      uploadProgress.total = 0
      // ローディング状態を終了
      loading.value = false

      // 結果を集計
      const successCount = results.filter(r => r.status === 'success').length
      const errorCount = results.filter(r => r.status === 'error').length
      const totalImported = results
        .filter(r => r.status === 'success')
        .reduce((sum, r) => sum + r.importedCount, 0)

      // 完了結果ログ
      console.log('フォルダーアップロード完了結果:', {
        成功ファイル数: successCount,
        エラーファイル数: errorCount,
        合計インポート件数: totalImported,
        詳細: results
      })

      // 成功した処理がある場合
      if (successCount > 0 || totalImported > 0) {
        // 成功メッセージを表示
        alert(`${successCount}個のファイルを処理完了！\n合計 ${totalImported}件のデータをインポートしました。${errorCount > 0 ? `\n${errorCount}個のファイルは空またはエラーでした。` : ''}`)

        // データを再読み込み
        await loadData()
      } else {
        // 失敗メッセージを表示
        alert('処理可能なデータが見つかりませんでした。CSVファイルの内容を確認してください。')
      }
    }

    // チャートナビゲーション状態の更新ハンドラー
    const handleNavigationState = (state) => {
      // ローカル状態を更新
      chartNavigationState.value = state
      // 親コンポーネント（App.vue）に状態を通知
      emit('chart-navigation-updated', state)
    }

    // コンポーネントマウント時の初期処理
    onMounted(() => {
      // データを読み込み
      loadData()
    })

    // テンプレートで使用する変数と関数を返却
    return {
      loading,
      chartData,
      summaryData,
      uploadSuccess,
      handleFileUpload,
      handleFolderUpload,
      chartNavigationState,
      handleNavigationState
    }
  }
}
</script>

<style lang="scss" scoped>
/* ホームページのメインコンテナ */
.home-page {

}

/* ファイルアップロードと対応形式表示のグリッドコンテナ */
.upload-container {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 30px;
  margin-bottom: 30px;
}

/* ファイルアップロード部分のスタイル */
.upload-section {
  background: #f8f9fa;
  border: 2px dashed #dee2e6;
  border-radius: 10px;
  padding: 40px;
  text-align: center;
  transition: all 0.3s ease;

  /* ホバー時のスタイル変更 */
  &:hover {
    border-color: #4CAF50;
    background: #f0f8ff;
  }
}

/* アップロードアイコンのスタイル */
.upload-icon {
  font-size: 3em;
  margin-bottom: 20px;
  color: #6c757d;
}

/* アップロード説明テキストのスタイル */
.upload-text {
  font-size: 1.2em;
  color: #495057;
  margin-bottom: 15px;
}

/* 対応ファイル形式テーブルセクションのスタイル */
.format-table-section {
  background: white;
  border-radius: 10px;
  padding: 25px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);

  /* セクションタイトルのスタイル */
  h3 {
    margin-bottom: 20px;
    color: #333;
    font-size: 1.2em;
  }
}

/* 対応形式テーブルのスタイル */
.format-table {
  width: 100%;
  border-collapse: collapse;

  /* テーブルヘッダーのスタイル */
  th {
    background: #f8f9fa;
    padding: 12px;
    text-align: left;
    border-bottom: 2px solid #dee2e6;
    font-weight: 600;
    font-size: 0.9em;
  }

  /* テーブルセルのスタイル */
  td {
    padding: 12px;
    border-bottom: 1px solid #dee2e6;
    font-size: 0.9em;
  }

  /* テーブル行のホバースタイル */
  tr:hover {
    background: #f8f9fa;
  }
}

/* ステータスバッジのスタイル */
.status {
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 0.8em;
  font-weight: bold;

  /* 対応済みステータスのスタイル */
  &.supported {
    background: #d4edda;
    color: #155724;
  }

  /* 予定ステータスのスタイル */
  &.planned {
    background: #fff3cd;
    color: #856404;
  }
}

/* グラフセクションのスタイル */
.chart-section {
  background: white;
  border-radius: 10px;
  padding: 30px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}

/* グラフヘッダーのスタイル */
.chart-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 25px;
  border-bottom: 2px solid #f8f9fa;
  padding-bottom: 15px;
}

/* グラフタイトルのスタイル */
.chart-title {
  font-size: 1.5em;
  color: #333;
}

/* 期間選択ボタンコンテナのスタイル */
.period-selector {
  display: flex;
  gap: 10px;
}

/* 期間選択ボタンのスタイル */
.period-btn {
  background: #e9ecef;
  border: 1px solid #dee2e6;
  padding: 8px 15px;
  border-radius: 20px;
  cursor: pointer;
  transition: all 0.3s ease;

  /* アクティブ状態のスタイル */
  &.active {
    background: #4CAF50;
    color: white;
    border-color: #4CAF50;
  }

  /* 非アクティブ時のホバースタイル */
  &:hover:not(.active) {
    background: #dee2e6;
  }
}

/* プライバシートグルのスタイル */
.privacy-toggle {
  text-align: center;
  margin: 20px 0;
}

</style>