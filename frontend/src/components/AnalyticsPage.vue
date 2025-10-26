<template lang="pug">
// === メインコンテナ ===
.analytics-page
  // === 月選択ナビゲーション ===
  // ユーザーが表示する月を選択・切り替えるためのUI
  .month-navigation
    // ナビゲーションコントロール（前月ボタン・月選択・次月ボタン）
    .nav-controls
      // 前月へ移動するボタン
      // :disabled - 前月がない、またはローディング中の場合は無効化
      button.nav-btn(@click="previousMonth" :disabled="!canGoPrevious || isLoading || isNavigating")
        // 左向き矢印アイコン（SVG）
        svg(viewBox="0 0 24 24" width="16" height="16")
          path(d="M15 18l-6-6 6-6v12z")

      // 月選択ドロップダウン（クリックで月選択ピッカーを表示/非表示）
      // :class - ローディング中の場合は"loading"クラスを追加
      .month-selector(@click="toggleMonthPicker" :class="{ loading: isLoading || isNavigating }")
        // 現在選択中の年月を表示（例: "2025年8月"）
        span.selected-month {{ formattedCurrentMonth }}
        // ローディング中のインジケーター（データ読み込み中のみ表示）
        span.loading-indicator(v-if="isLoading || isNavigating") 読み込み中...
        // ドロップダウン矢印（通常時のみ表示、ピッカーの開閉状態で上下反転）
        span.dropdown-arrow(v-else)
          svg(viewBox="0 0 24 24" width="14" height="14")
            // ピッカーが開いている場合は上向き矢印
            path(d="M7 14l5-5 5 5z" v-if="showMonthPicker")
            // ピッカーが閉じている場合は下向き矢印
            path(d="M7 10l5 5 5-5z" v-else)

      // 次月へ移動するボタン
      // :disabled - 次月がない（最新月）、またはローディング中の場合は無効化
      button.nav-btn(@click="nextMonth" :disabled="!canGoNext || isLoading || isNavigating")
        // 右向き矢印アイコン（SVG）
        svg(viewBox="0 0 24 24" width="16" height="16")
          path(d="M9 18l6-6-6-6v12z")
    
    // === 月選択ピッカー（ドロップダウンメニュー） ===
    // v-show - showMonthPickerがtrueの場合のみ表示
    .month-picker(v-show="showMonthPicker")
      // 年選択ナビゲーション（前年・現在年・次年ボタン）
      .year-nav-header
        // 前年へ移動するボタン
        // :disabled - 前年データがない、またはローディング中の場合は無効化
        button.year-btn(@click="previousYear" :disabled="!canGoPreviousYear || isLoading || isNavigating")
          // ダブル左向き矢印アイコン（年の移動を示す）
          svg(viewBox="0 0 24 24" width="18" height="18")
            path(d="M18 17l-6-5 6-5v10zM12 17l-6-5 6-5v10z")

        // 現在選択中の年を表示（例: "2025年"）
        .year-display {{ currentYear }}年

        // 次年へ移動するボタン
        // :disabled - 次年がない（未来）、またはローディング中の場合は無効化
        button.year-btn(@click="nextYear" :disabled="!canGoNextYear || isLoading || isNavigating")
          // ダブル右向き矢印アイコン（年の移動を示す）
          svg(viewBox="0 0 24 24" width="18" height="18")
            path(d="M6 17l6-5-6-5v10zM12 17l6-5-6-5v10z")

      // 月選択グリッド（1月〜12月を4列3行で表示）
      .month-grid
        // 1〜12の月をループして表示
        // v-for - 12ヶ月分の月アイテムを生成
        .month-item(
          v-for="month in 12"
          :key="month"
          :class="{ active: month === currentMonth, 'has-data': hasDataForMonth(month) }"
          @click="hasDataForMonth(month) ? selectMonth(month) : null"
        ) {{ month }}月
          // :class説明:
          // - active: 現在選択中の月の場合に適用（背景色を変更）
          // - has-data: データが存在する月の場合に適用（クリック可能、色を変更）
          // @click説明:
          // - データがある月のみクリック可能（hasDataForMonthがtrueの場合）
          // - クリック時にselectMonth関数を呼び出し、その月のデータを読み込む

  // === 統計カードセクション ===
  // 選択された月の支出統計を4つのカードで表示
  .stats-cards
    // カード1: 総支出額
    .stat-card
      .stat-title 選択期間の総支出
      // プライバシーモードの場合は金額を隠す、通常時は総支出額を表示
      .stat-value {{ isPrivacyMode ? '¥***' : formatCurrency(statsData.totalAmount) }}

    // カード2: 最大支出額（.redクラスで赤系の背景色を適用）
    .stat-card.red
      .stat-title 最も高い支出
      // プライバシーモードの場合は金額を隠す、通常時は最大支出額を表示
      .stat-value {{ isPrivacyMode ? '¥***' : formatCurrency(statsData.maxAmount) }}

    // カード3: 1日平均支出額（.greenクラスで緑系の背景色を適用）
    .stat-card.green
      .stat-title 1日平均支出
      // プライバシーモードの場合は金額を隠す、通常時は1日平均支出額を表示
      .stat-value {{ isPrivacyMode ? '¥***' : formatCurrency(statsData.averageDaily) }}

    // カード4: 取引件数（.orangeクラスでオレンジ系の背景色を適用）
    .stat-card.orange
      .stat-title 取引件数
      // 取引件数は常に表示（プライバシーモードでも隠さない）
      .stat-value {{ statsData.transactionCount }}件
  
  
  // === チャート表示グリッド ===
  // 円グラフと折れ線グラフを2カラムで表示（レスポンシブ対応）
  .analytics-grid
    // === カテゴリ別円グラフセクション ===
    .chart-section
      .chart-title カテゴリ別支出割合
      .chart-container
        .pie-chart-wrapper
          // 円グラフ描画用のcanvas要素（ref="categoryPieChart"でJavaScriptから参照）
          canvas(ref="categoryPieChart")
          // カスタム凡例コンテナ（カテゴリ名と金額を表示、ref="chartLegend"でJavaScriptから参照）
          .chart-legend(ref="chartLegend")

    // === 日別推移折れ線グラフセクション ===
    .chart-section
      .chart-title 日別支出推移
      .chart-container
        // 折れ線グラフ描画用のcanvas要素（ref="dailyLineChart"でJavaScriptから参照）
        canvas(ref="dailyLineChart")

  // === 取引明細テーブルセクション ===
  // .full-width - グリッド全体の幅を使用（2カラムをまたぐ）
  .details-section.full-width
    .chart-title 取引明細

    // === フィルタリング・ソートバー ===
    .filter-bar
      // カテゴリフィルタ選択ドロップダウン
      // v-model - selectedCategoryと双方向バインディング
      // @change - 選択変更時にapplyFilters関数を実行
      select.filter-select(v-model="selectedCategory" @change="applyFilters")
        option(value="") 全カテゴリ
        option(value="投資") 投資
        option(value="食費") 食費
        option(value="日用品費") 日用品費
        option(value="娯楽費") 娯楽費
        option(value="住宅費") 住宅費
        option(value="交通費") 交通費
        option(value="その他") その他

      // ソート順選択ドロップダウン
      // v-model - sortOrderと双方向バインディング
      // @change - 選択変更時にapplyFilters関数を実行
      select.filter-select(v-model="sortOrder" @change="applyFilters")
        option(value="amount_desc") 金額順（高い順）
        option(value="amount_asc") 金額順（安い順）
        option(value="date_desc") 日付順（新しい順）
        option(value="date_asc") 日付順（古い順）

    // === トランザクションテーブル ===
    .table-container
      table.transaction-table
        // テーブルヘッダー
        thead
          tr
            th 日付
            th 店舗・サービス
            th カテゴリ
            th 金額

        // テーブルボディ（トランザクションデータをループ表示）
        tbody
          // v-for - transactions配列の各トランザクションをループ
          // :key - 各行を一意に識別するためのキー（インデックス使用）
          tr(v-for="(transaction, index) in transactions" :key="index")
            // 日付列（例: "2025/8/13"）
            td {{ transaction.date }}
            // 店舗名列
            td {{ transaction.store }}
            // カテゴリ列（CategoryTagコンポーネントを使用、クリックでカテゴリ変更可能）
            td
              CategoryTag(
                :category="transaction.category"
                :categoryText="transaction.categoryText"
                @change-category="handleCategoryChange(index, $event)"
              )
                // :category - CSSクラス名（例: "food", "investment"）
                // :categoryText - 表示用カテゴリ名（例: "食費", "投資"）
                // @change-category - カテゴリ変更イベントをハンドル
            // 金額列（右寄せ表示、プライバシーモード時は隠す）
            td.amount {{ isPrivacyMode ? '¥***' : transaction.amount }}
</template>

<script>
// Vue 3のリアクティブシステムとライフサイクルフックをインポート
import { ref, onMounted, onBeforeUnmount, computed, reactive } from 'vue'
// Chart.jsライブラリとすべての登録可能な要素をインポート
import { Chart, registerables } from 'chart.js'
// カテゴリタグコンポーネントをインポート
import CategoryTag from './CategoryTag.vue'
// API通信用のサービスをインポート
import apiService from '../services/api.js'

// Chart.jsのすべての登録可能な要素（グラフタイプ、プラグインなど）を登録
Chart.register(...registerables)

export default {
  name: 'AnalyticsPage',
  components: {
    CategoryTag
  },
  props: {
    // プライバシーモードのフラグ（金額を隠す機能）
    isPrivacyMode: {
      type: Boolean,
      default: false
    },
    // チャートナビゲーションの状態（親コンポーネントから受け取る）
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
  setup(props) {
    // === DOM参照 ===
    const categoryPieChart = ref(null) // カテゴリ別円グラフのcanvas要素への参照
    const dailyLineChart = ref(null)   // 日別推移の折れ線グラフのcanvas要素への参照
    const categoryChartInstance = ref(null) // カテゴリ別円グラフのChartインスタンス
    const dailyChartInstance = ref(null)    // 日別推移折れ線グラフのChartインスタンス
    const chartLegend = ref(null) // カスタム凡例のコンテナ要素への参照

    // === 月選択の状態管理 ===
    const currentYear = ref(new Date().getFullYear()) // 現在選択中の年
    const currentMonth = ref(new Date().getMonth() + 1) // 現在選択中の月（1-12）
    const selectedYear = ref(new Date().getFullYear()) // 選択された年
    const showMonthPicker = ref(false) // 月選択ピッカーの表示/非表示フラグ
    const availableMonths = ref([]) // データが存在する月のリスト（フォーマット: YYYY-MM）
    const initialDataLoaded = ref(false) // 初回データ読み込み完了フラグ
    const isLoading = ref(false) // データ読み込み中フラグ（重複リクエスト防止用）
    const isNavigating = ref(false) // ナビゲーション処理中フラグ（連続クリック防止用）
    const dataCache = new Map() // 月次データのキャッシュ（キー: "YYYY-MM", 値: データオブジェクト）

    // === 統計データ ===
    // reactiveでオブジェクト全体をリアクティブに管理
    const statsData = reactive({
      totalAmount: 0,       // 選択期間の総支出額
      maxAmount: 0,         // 最も高い支出額
      averageDaily: 0,      // 1日平均支出額
      transactionCount: 0   // 取引件数
    })

    // === トランザクションデータ ===
    const transactions = ref([])     // フィルタリング・ソート後の表示用トランザクションリスト
    const allTransactions = ref([]) // フィルタリング前の全トランザクションデータ

    // === フィルタリング・ソート関連 ===
    const selectedCategory = ref('') // 選択中のカテゴリフィルタ（空文字列 = 全カテゴリ）
    const sortOrder = ref('date_desc') // ソート順序（デフォルト: 日付降順）
    
    // === フィルタリング・ソート機能 ===
    // 選択されたカテゴリとソート順序に基づいてトランザクションをフィルタリング・ソート
    const applyFilters = () => {
      // 全トランザクションデータのコピーを作成
      let filtered = [...allTransactions.value]

      // カテゴリフィルタリング
      // selectedCategoryに値がある場合のみフィルタリングを実行
      if (selectedCategory.value) {
        filtered = filtered.filter(t => t.categoryText === selectedCategory.value)
      }

      // ソート処理
      // sortOrder.valueの値に応じて異なるソート関数を適用
      filtered.sort((a, b) => {
        switch (sortOrder.value) {
          case 'amount_desc': // 金額降順（高い順）
            // 金額から数字以外の文字（¥, カンマなど）を除去して数値として比較
            return parseFloat(b.amount.replace(/[^\d]/g, '')) - parseFloat(a.amount.replace(/[^\d]/g, ''))
          case 'amount_asc': // 金額昇順（安い順）
            return parseFloat(a.amount.replace(/[^\d]/g, '')) - parseFloat(b.amount.replace(/[^\d]/g, ''))
          case 'date_desc': // 日付降順（新しい順）
            return new Date(b.rawDate) - new Date(a.rawDate)
          case 'date_asc': // 日付昇順（古い順）
            return new Date(a.rawDate) - new Date(a.rawDate)
          default:
            return 0 // 変更なし
        }
      })

      // フィルタリング・ソート済みのデータを表示用変数に代入
      transactions.value = filtered
    }

    // === カテゴリ変更ハンドラ ===
    // ユーザーがトランザクションのカテゴリを変更した際に呼び出される
    const handleCategoryChange = async (index, newCategory) => {
      try {
        // 変更対象のトランザクションを取得
        const transaction = transactions.value[index]

        // APIを呼び出してバックエンドのカテゴリを更新
        const result = await apiService.updateTransaction(transaction.id, {
          category_name: newCategory.text
        })

        console.log('カテゴリ更新成功:', result)

        // カテゴリ名からCSSクラス名へのマッピング関数
        // 日本語のカテゴリ名を英語のクラス名に変換
        const getCategoryClass = (categoryName) => {
          const mapping = {
            '投資': 'investment',
            '食費': 'food',
            '日用品費': 'daily',
            '娯楽費': 'entertainment',
            '住宅費': 'housing',
            '交通費': 'transport',
            'その他': 'other'
          }
          return mapping[categoryName] || 'other'
        }

        // ローカルのトランザクションデータを更新
        transactions.value[index].category = getCategoryClass(newCategory.text)
        transactions.value[index].categoryText = newCategory.text

        // チャートと統計サマリーを再読み込みして最新データを反映
        await loadMonthData()

      } catch (error) {
        console.error('カテゴリ更新エラー:', error)
        alert('カテゴリの更新に失敗しました: ' + error.message)
      }
    }
    
    // === 月選択機能（Computed Properties） ===

    // 現在選択中の年月を日本語形式でフォーマット（例: "2025年8月"）
    const formattedCurrentMonth = computed(() => {
      return `${currentYear.value}年${currentMonth.value}月`
    })

    // 前月ボタンが有効かどうかを判定するComputed Property
    // 戻り値: true = 前月に移動可能、false = 移動不可（ボタン無効化）
    const canGoPrevious = computed(() => {
      // === 親コンポーネントからチャートナビゲーション状態が提供されている場合 ===
      if (props.chartNavigationState && props.chartNavigationState.availableMonths.length > 0) {
        // 現在の年月キーを生成（フォーマット: "YYYY/MM"）
        const currentMonthKey = `${currentYear.value}/${currentMonth.value.toString().padStart(2, '0')}`
        // 親から提供された利用可能な月のリスト
        const chartMonths = props.chartNavigationState.availableMonths
        // 現在の月が利用可能な月リスト内のどの位置にあるかを取得
        const currentIndex = chartMonths.indexOf(currentMonthKey)

        // 現在選択中の月が利用可能な月リストに存在しない場合
        if (currentIndex === -1) {
          // より古い月がリストに存在するかチェック（文字列比較）
          return chartMonths.some(month => month < currentMonthKey)
        }

        // リストの最初の要素（インデックス0）でない場合は前月に移動可能
        return currentIndex > 0
      }

      // === フォールバック: ローカルの利用可能月データを使用 ===
      // 利用可能な月データがない場合は移動不可
      if (availableMonths.value.length === 0) return false

      // 現在の年月キーを生成（フォーマット: "YYYY-MM"）
      const currentMonthKey = `${currentYear.value}-${currentMonth.value.toString().padStart(2, '0')}`
      // 現在の月がリスト内のどの位置にあるかを取得
      const currentIndex = availableMonths.value.indexOf(currentMonthKey)

      // 現在選択中の月が利用可能な月リストに存在しない場合
      if (currentIndex === -1) {
        // より古い月がリストに存在するかチェック
        return availableMonths.value.some(month => month < currentMonthKey)
      }

      // リストの最初の要素でない場合は前月に移動可能
      return currentIndex > 0
    })
    
    const canGoNext = computed(() => {
      // チャートナビゲーション状態がある場合はそれを優先
      if (props.chartNavigationState && props.chartNavigationState.availableMonths.length > 0) {
        const currentMonthKey = `${currentYear.value}/${currentMonth.value.toString().padStart(2, '0')}`
        const chartMonths = props.chartNavigationState.availableMonths
        const currentIndex = chartMonths.indexOf(currentMonthKey)
        
        if (currentIndex === -1) {
          // 現在選択中の月がチャートにない場合、より新しい月があるかチェック
          return chartMonths.some(month => month > currentMonthKey)
        }
        
        return currentIndex < chartMonths.length - 1
      }
      
      // フォールバック: 既存のロジック
      if (availableMonths.value.length === 0) return false
      
      const currentMonthKey = `${currentYear.value}-${currentMonth.value.toString().padStart(2, '0')}`
      const currentIndex = availableMonths.value.indexOf(currentMonthKey)
      
      if (currentIndex === -1) {
        return availableMonths.value.some(month => month > currentMonthKey)
      }
      
      return currentIndex < availableMonths.value.length - 1
    })
    
    const canGoNextYear = computed(() => {
      const now = new Date()
      return currentYear.value < now.getFullYear()
    })
    
    const canGoPreviousYear = computed(() => {
      // チャートナビゲーション状態がある場合はそれを優先
      if (props.chartNavigationState && props.chartNavigationState.availableMonths.length > 0) {
        const chartMonths = props.chartNavigationState.availableMonths
        // チャートの利用可能な月から最も古い年を取得 (YYYY/MM format)
        const oldestMonthStr = chartMonths[0] // 最初の要素が最も古い
        const oldestYear = parseInt(oldestMonthStr.split('/')[0])
        return currentYear.value > oldestYear
      }
      
      // フォールバック: 最も古いデータの年まで戻れるかチェック
      if (availableMonths.value.length === 0) return false
      
      const oldestMonth = availableMonths.value[0] // ソート済み前提
      const oldestYear = parseInt(oldestMonth.split('-')[0])
      return currentYear.value > oldestYear
    })
    
    const hasDataForMonth = (month) => {
      // チャートナビゲーション状態がある場合はそれを優先
      if (props.chartNavigationState && props.chartNavigationState.availableMonths.length > 0) {
        const yearToCheck = currentYear.value
        const monthKey = `${yearToCheck}/${month.toString().padStart(2, '0')}`
        return props.chartNavigationState.availableMonths.includes(monthKey)
      }
      
      // フォールバック: 既存のロジック
      const yearToCheck = currentYear.value
      const monthKey = `${yearToCheck}-${month.toString().padStart(2, '0')}`
      const hasData = availableMonths.value.includes(monthKey)
      
      return hasData
    }
    
    // === 月ナビゲーション関数 ===

    // 前月へ移動する処理
    const previousMonth = async () => {
      // 既にローディング中またはナビゲーション中の場合は処理を中断（重複リクエスト防止）
      if (isLoading.value || isNavigating.value) return

      // ナビゲーション中フラグを立てる
      isNavigating.value = true
      try {
        // 現在が1月の場合は前年の12月に移動
        if (currentMonth.value === 1) {
          currentMonth.value = 12
          currentYear.value--
        } else {
          // それ以外は月を1つ減らす
          currentMonth.value--
        }
        // 新しい年月のデータを読み込む
        await loadMonthData()
      } finally {
        // デバウンス: 連続クリック防止のため500ms後にナビゲーション中フラグを解除
        setTimeout(() => {
          isNavigating.value = false
        }, 500)
      }
    }

    // 次月へ移動する処理
    const nextMonth = async () => {
      // 既にローディング中またはナビゲーション中の場合は処理を中断（重複リクエスト防止）
      if (isLoading.value || isNavigating.value) return

      // ナビゲーション中フラグを立てる
      isNavigating.value = true
      try {
        // 現在が12月の場合は翌年の1月に移動
        if (currentMonth.value === 12) {
          currentMonth.value = 1
          currentYear.value++
        } else {
          // それ以外は月を1つ増やす
          currentMonth.value++
        }
        // 新しい年月のデータを読み込む
        await loadMonthData()
      } finally {
        // デバウンス: 連続クリック防止のため500ms後にナビゲーション中フラグを解除
        setTimeout(() => {
          isNavigating.value = false
        }, 500)
      }
    }

    // 月選択ピッカーの表示/非表示を切り替える
    const toggleMonthPicker = () => {
      console.log('Toggle month picker clicked', showMonthPicker.value)
      // 現在の状態を反転（true→false、false→true）
      showMonthPicker.value = !showMonthPicker.value
    }

    // ユーザーが月選択ピッカーから特定の月を選択した際の処理
    const selectMonth = async (month) => {
      // 既にローディング中またはナビゲーション中の場合は処理を中断
      if (isLoading.value || isNavigating.value) return

      // 重複リクエスト防止: 既に選択中の月を再度クリックした場合
      if (currentMonth.value === month) {
        // ピッカーを閉じるだけで処理を終了
        showMonthPicker.value = false
        return
      }

      // ナビゲーション中フラグを立てる
      isNavigating.value = true
      try {
        // 選択された月を現在の月に設定
        currentMonth.value = month
        // 月選択ピッカーを閉じる
        showMonthPicker.value = false
        // 選択された月のデータを読み込む
        await loadMonthData()
      } catch (error) {
        console.error('月選択エラー:', error)
      } finally {
        // デバウンス: 200ms後にナビゲーション中フラグを解除
        setTimeout(() => {
          isNavigating.value = false
        }, 200)
      }
    }

    // === 年ナビゲーション関数 ===

    // 前年へ移動する処理
    const previousYear = async () => {
      // 既にローディング中またはナビゲーション中の場合は処理を中断
      if (isLoading.value || isNavigating.value) return

      // ナビゲーション中フラグを立てる
      isNavigating.value = true
      try {
        // 年を1つ減らす
        currentYear.value--
        // 新しい年のデータを読み込む（月は変更しない）
        await loadMonthData()
      } finally {
        // デバウンス: 200ms後にナビゲーション中フラグを解除
        setTimeout(() => {
          isNavigating.value = false
        }, 200)
      }
    }

    // 次年へ移動する処理
    const nextYear = async () => {
      // 既にローディング中またはナビゲーション中の場合は処理を中断
      if (isLoading.value || isNavigating.value) return

      // 次年に移動可能かチェック（未来の年には移動不可）
      if (canGoNextYear.value) {
        // ナビゲーション中フラグを立てる
        isNavigating.value = true
        try {
          // 年を1つ増やす
          currentYear.value++
          // 新しい年のデータを読み込む（月は変更しない）
          await loadMonthData()
        } finally {
          // デバウンス: 200ms後にナビゲーション中フラグを解除
          setTimeout(() => {
            isNavigating.value = false
          }, 200)
        }
      }
    }
    
    // === 利用可能月データの初期読み込み ===
    // アプリケーション起動時に、データが存在する月のリストを取得し、最新月を表示
    const loadAvailableMonths = async () => {
      try {
        // APIから全トランザクションデータを取得（フィルタなし）
        const transactionData = await apiService.getTransactions()

        // トランザクションデータが存在する場合
        if (transactionData.transactions && transactionData.transactions.length > 0) {
          // 全トランザクションから年月を抽出してSetに格納（重複排除）
          const monthSet = new Set()
          transactionData.transactions.forEach(transaction => {
            // トランザクション日付をDateオブジェクトに変換
            const date = new Date(transaction.transaction_date)
            // 年月キーを生成（フォーマット: "YYYY-MM"）
            const monthKey = `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}`
            // Setに追加（自動的に重複が排除される）
            monthSet.add(monthKey)
          })

          // Setを配列に変換し、古い順にソート
          availableMonths.value = Array.from(monthSet).sort()

          // 最新の取引日付を取得するため、トランザクションを日付降順でソート
          const sortedTransactions = transactionData.transactions.sort((a, b) =>
            new Date(b.transaction_date) - new Date(a.transaction_date)
          )
          // 最新のトランザクションの日付を取得
          const latestDate = new Date(sortedTransactions[0].transaction_date)

          // 初期表示は最新のトランザクションがある年月に設定
          currentYear.value = latestDate.getFullYear()
          currentMonth.value = latestDate.getMonth() + 1
          initialDataLoaded.value = true

          console.log(`初期表示: ${currentYear.value}年${currentMonth.value}月`)

          // 最新月のデータを読み込む
          await loadMonthData()
        } else {
          // トランザクションデータがない場合は現在の年月を設定
          const now = new Date()
          currentYear.value = now.getFullYear()
          currentMonth.value = now.getMonth() + 1
          initialDataLoaded.value = true
        }
      } catch (error) {
        console.error('利用可能月データ読み込みエラー:', error)
        // エラーが発生した場合も現在の年月を設定（フォールバック）
        const now = new Date()
        currentYear.value = now.getFullYear()
        currentMonth.value = now.getMonth() + 1
      }
    }
    
    // === 月次データ読み込み ===
    // 選択された年月のデータを読み込み、キャッシュを活用してパフォーマンスを最適化
    const loadMonthData = async () => {
      // 既に読み込み中の場合は処理しない（重複リクエスト防止）
      if (isLoading.value) return

      // キャッシュキーを生成（例: "2025-8"）
      const cacheKey = `${currentYear.value}-${currentMonth.value}`

      // キャッシュにデータが存在する場合はキャッシュから取得
      if (dataCache.has(cacheKey)) {
        console.log('キャッシュからデータを取得:', cacheKey)
        const cachedData = dataCache.get(cacheKey)

        // キャッシュデータを使用してUI更新（APIリクエスト不要）
        Object.assign(statsData, cachedData.stats)
        allTransactions.value = cachedData.transactions
        applyFilters()
        updateCharts()
        return
      }

      // ローディング状態を開始
      isLoading.value = true
      try {
        // APIから月次統計データを取得
        const monthlyData = await apiService.getMonthlyData(currentYear.value, currentMonth.value)

        // 統計データを更新
        statsData.totalAmount = monthlyData.total_amount || 0 // 総支出額
        statsData.transactionCount = monthlyData.transaction_count || 0 // 取引件数
        // 1日平均支出額を計算（総支出額 ÷ その月の日数）
        statsData.averageDaily = monthlyData.total_amount ? Math.round(monthlyData.total_amount / new Date(currentYear.value, currentMonth.value, 0).getDate()) : 0

        // APIから取引明細データを取得（月でフィルタリング）
        const transactionData = await apiService.getTransactions({
          month: `${currentYear.value}-${currentMonth.value.toString().padStart(2, '0')}`
        })

        // カテゴリ名からCSSクラス名へのマッピング関数
        const getCategoryClass = (categoryName) => {
          const mapping = {
            '投資': 'investment',
            '食費': 'food',
            '日用品費': 'daily',
            '娯楽費': 'entertainment',
            '住宅費': 'housing',
            '交通費': 'transport',
            'その他': 'other'
          }
          return mapping[categoryName] || 'other'
        }

        // 取得したトランザクションデータを画面表示用にフォーマット
        allTransactions.value = transactionData.transactions.map(t => ({
          date: new Date(t.transaction_date).toLocaleDateString('ja-JP'), // 日本語表示用の日付
          rawDate: t.transaction_date, // ソート用の生データ（ISO形式）
          store: t.store_name, // 店舗名
          category: getCategoryClass(t.category?.name || 'その他'), // CSSクラス名
          categoryText: t.category?.name || 'その他', // 表示用カテゴリ名
          amount: formatCurrency(t.amount), // フォーマット済み金額（例: "¥1,000"）
          id: t.id // トランザクションID
        }))

        // フィルタリング・ソートを適用
        applyFilters()

        // 最大支出額を計算
        if (transactions.value.length > 0) {
          // 全トランザクションから金額を数値として抽出
          const amounts = transactions.value.map(t => parseFloat(t.amount.replace(/[^\d]/g, '')))
          statsData.maxAmount = Math.max(...amounts) // 最大値を取得
        }

        // チャートを更新
        updateCharts()

        // データをキャッシュに保存（次回の高速読み込み用）
        dataCache.set(cacheKey, {
          stats: { ...statsData }, // 統計データのコピー
          transactions: [...allTransactions.value] // トランザクションデータのコピー
        })

        // キャッシュサイズ制限（最大10件まで保持）
        if (dataCache.size > 10) {
          // 最も古いキャッシュを削除
          const firstKey = dataCache.keys().next().value
          dataCache.delete(firstKey)
        }

      } catch (error) {
        console.error('月次データ読み込みエラー:', error)
        // エラー時もUIを正常状態に戻す（空データで初期化）
        allTransactions.value = []
        Object.assign(statsData, {
          totalAmount: 0,
          maxAmount: 0,
          averageDaily: 0,
          transactionCount: 0
        })
      } finally {
        // 処理完了後に必ずloading状態を解除（try/catchどちらでも実行される）
        isLoading.value = false
      }
    }
    

    // === ユーティリティ関数 ===

    // 金額を通貨形式（￥マーク付き、カンマ区切り）にフォーマット
    // 引数: amount - 数値（小数点以下は四捨五入される）
    // 戻り値: フォーマット済み文字列（例: "￥1,234"）
    const formatCurrency = (amount) => {
      return '￥' + Math.round(amount).toLocaleString()
    }

    // === カスタム凡例生成関数 ===
    // 円グラフの横に表示するカスタム凡例を動的に生成
    // Chart.jsのデフォルト凡例では金額を表示できないため、独自に実装
    // 引数: categoryData - カテゴリ別データの配列（category, color, totalを含む）
    const generateCustomLegend = (categoryData) => {
      // 凡例を表示するコンテナ要素を取得
      const legendContainer = chartLegend.value
      // コンテナが存在しない場合は処理を中断
      if (!legendContainer) return

      // 既存の凡例をクリア（古いデータを削除）
      legendContainer.innerHTML = ''

      // 各カテゴリに対して凡例アイテムを生成
      categoryData.forEach(item => {
        // 凡例アイテム全体のコンテナ（div要素）を作成
        const legendItem = document.createElement('div')
        legendItem.className = 'legend-item'
        legendItem.style.display = 'flex'           // フレックスボックスレイアウト
        legendItem.style.flexDirection = 'row'      // 横並び
        legendItem.style.alignItems = 'center'      // 垂直方向中央揃え

        // 色ボックス（カテゴリの色を示す四角形）を作成
        const colorBox = document.createElement('div')
        colorBox.className = 'legend-color'
        colorBox.style.backgroundColor = item.color || '#999999'  // カテゴリの色（未定義時はグレー）
        colorBox.style.width = '14px'               // 幅14px
        colorBox.style.height = '14px'              // 高さ14px
        colorBox.style.borderRadius = '3px'         // 角を丸く
        colorBox.style.marginRight = '8px'          // 右側にマージン
        colorBox.style.flexShrink = '0'             // サイズを固定（縮小しない）
        colorBox.style.display = 'inline-block'

        // テキストコンテナ（カテゴリ名と金額を含む）を作成
        const textContainer = document.createElement('div')
        textContainer.className = 'legend-text-container'

        // カテゴリ名ラベル（例: "食費"）を作成
        const labelText = document.createElement('span')
        labelText.className = 'legend-label'
        labelText.textContent = item.category

        // 金額テキスト（例: "¥12,345"）を作成
        const valueText = document.createElement('span')
        valueText.className = 'legend-value'
        if (props.isPrivacyMode) {
          // プライバシーモード時は金額を隠す
          valueText.textContent = '¥*******'
        } else {
          // 通常時は金額を表示（四捨五入 + カンマ区切り）
          valueText.textContent = '¥' + Math.round(item.total).toLocaleString()
        }

        // テキストコンテナにラベルと金額を追加
        textContainer.appendChild(labelText)
        textContainer.appendChild(valueText)

        // 凡例アイテムに色ボックスとテキストコンテナを追加
        legendItem.appendChild(colorBox)
        legendItem.appendChild(textContainer)

        // 凡例コンテナに凡例アイテムを追加
        legendContainer.appendChild(legendItem)
      })
    }

    // === チャート更新処理 ===
    // カテゴリ別円グラフと日別推移折れ線グラフを更新
    const updateCharts = async () => {
      try {
        // === 円グラフ（カテゴリ別支出）のデータ準備 ===
        // APIからカテゴリ別集計データを取得
        const monthlyData = await apiService.getMonthlyData(currentYear.value, currentMonth.value)

        // APIレスポンスからカテゴリ別データを取得
        const categoryData = monthlyData.category_totals || []

        // 全カテゴリを定義（データがない場合も0円で表示するため）
        const allCategories = [
          { category: '投資', color: '#FF6384' },      // 赤系
          { category: '食費', color: '#4BC0C0' },      // シアン系
          { category: '日用品費', color: '#9966FF' },  // 紫系
          { category: '娯楽費', color: '#36A2EB' },    // 青系
          { category: '住宅費', color: '#FF9F40' },    // オレンジ系
          { category: '交通費', color: '#FFCE56' },    // 黄系
          { category: 'その他', color: '#C9CBCF' }     // グレー系
        ]

        // データがあるカテゴリはAPIデータを使用、ないカテゴリは0で補完
        const completeData = allCategories.map(defaultCat => {
          const foundData = categoryData.find(apiCat => apiCat.category === defaultCat.category)
          return foundData || { ...defaultCat, total: 0 }
        })

        // Chart.js用にデータを配列に分解
        const categoryLabels = completeData.map(cat => cat.category)   // ラベル配列
        const categoryAmounts = completeData.map(cat => cat.total)     // 金額配列
        const categoryColors = completeData.map(cat => cat.color)      // 色配列

        // === 円グラフの描画 ===
        // 既存のチャートインスタンスがあれば破棄（メモリリーク防止）
        if (categoryChartInstance.value) {
          categoryChartInstance.value.destroy()
          categoryChartInstance.value = null
        }

        // データが存在し、canvas要素が準備できている場合にチャートを作成
        if (completeData.length > 0 && categoryPieChart.value) {
          // canvas要素の2Dコンテキストを取得
          const ctx1 = categoryPieChart.value.getContext('2d')
          // 新しいドーナツチャートを作成
          categoryChartInstance.value = new Chart(ctx1, {
              type: 'doughnut', // ドーナツ型の円グラフ
              data: {
                labels: categoryLabels, // カテゴリ名
                datasets: [{
                  data: categoryAmounts,           // 各カテゴリの金額
                  backgroundColor: categoryColors,  // 各カテゴリの色
                  borderWidth: 2,                   // セグメント境界線の太さ
                  borderColor: '#fff'               // セグメント境界線の色（白）
                }]
              },
              options: {
                responsive: true,            // レスポンシブ対応
                maintainAspectRatio: false,  // アスペクト比を固定しない
                plugins: {
                  legend: { display: false }, // デフォルトの凡例を非表示（カスタム凡例を使用）
                  tooltip: {
                    callbacks: {
                      // ツールチップのラベルをカスタマイズ
                      label: function(context) {
                        if (props.isPrivacyMode) {
                          // プライバシーモード時は金額を隠す
                          return context.label + ': ¥*******'
                        } else {
                          // 通常時は金額を表示（カンマ区切り）
                          return context.label + ': ¥' + context.parsed.toLocaleString()
                        }
                      }
                    }
                  }
                }
              }
            })

          // カスタム凡例を生成（金額表示付き）
          generateCustomLegend(completeData)
        }
        
        // === 折れ線グラフ（日別支出推移）のデータ準備 ===
        // APIから日別の支出データを取得（月の開始日〜終了日）
        const analyticsData = await apiService.getAnalyticsData(
          `${currentYear.value}-${currentMonth.value.toString().padStart(2, '0')}-01`, // 月の開始日
          `${currentYear.value}-${currentMonth.value.toString().padStart(2, '0')}-${new Date(currentYear.value, currentMonth.value, 0).getDate()}` // 月の終了日
        )

        // APIレスポンスから日別データを取得（オブジェクト形式: { "2025-08-01": 1000, ... }）
        const dailyData = analyticsData.daily_totals || {}
        // 日付をソート（古い順）
        const sortedDates = Object.keys(dailyData).sort()
        // 日付ラベルを "月/日" 形式にフォーマット
        const dailyLabels = sortedDates.map(date => {
          const d = new Date(date)
          return `${d.getMonth() + 1}/${d.getDate()}`
        })
        // 日付に対応する金額を配列化
        const dailyAmounts = sortedDates.map(date => dailyData[date] || 0)

        // === 折れ線グラフの描画 ===
        // 既存のチャートインスタンスがあれば破棄（メモリリーク防止）
        if (dailyChartInstance.value) {
          dailyChartInstance.value.destroy()
          dailyChartInstance.value = null
        }

        // データが存在し、canvas要素が準備できている場合にチャートを作成
        if (sortedDates.length > 0 && dailyLineChart.value) {
          // canvas要素の2Dコンテキストを取得
          const ctx2 = dailyLineChart.value.getContext('2d')
          // 新しい折れ線グラフを作成
          dailyChartInstance.value = new Chart(ctx2, {
              type: 'line', // 折れ線グラフ
              data: {
                labels: dailyLabels, // X軸ラベル（日付）
                datasets: [{
                  label: '支出額',
                  data: dailyAmounts,                      // Y軸データ（金額）
                  borderColor: '#38bdf8',                  // 線の色（水色）
                  backgroundColor: 'rgba(56, 189, 248, 0.1)', // 塗りつぶし色（半透明水色）
                  tension: 0.4,                            // 線の曲線度（0=直線、1=完全な曲線）
                  fill: true,                              // グラフの下を塗りつぶす
                  pointBackgroundColor: '#38bdf8',         // ポイント（点）の背景色
                  pointBorderColor: '#fff',                // ポイントの境界線色（白）
                  pointBorderWidth: 2                      // ポイントの境界線の太さ
                }]
              },
              options: {
                responsive: true,            // レスポンシブ対応
                maintainAspectRatio: false,  // アスペクト比を固定しない
                scales: {
                  y: { // Y軸（縦軸）の設定
                    beginAtZero: true,       // 0から開始
                    ticks: {
                      // Y軸ラベルのカスタマイズ
                      callback: function(value) {
                        if (props.isPrivacyMode) {
                          // プライバシーモード時は金額を隠す
                          return '¥*******'
                        } else {
                          // 通常時は金額を表示（カンマ区切り + スペースでパディング）
                          const formattedValue = '¥' + value.toLocaleString()
                          return formattedValue.padStart(8, ' ')
                        }
                      },
                      minWidth: 100,  // ラベル領域の最小幅
                      padding: 10     // ラベルとグラフの間のパディング
                    },
                    // Y軸の幅を調整（フィット後に実行）
                    afterFit: function(scale) {
                      scale.width = 100; // Y軸の幅を100pxに固定
                    }
                  }
                },
                plugins: {
                  legend: { display: false }, // 凡例を非表示
                  tooltip: {
                    callbacks: {
                      // ツールチップのラベルをカスタマイズ
                      label: function(context) {
                        if (props.isPrivacyMode) {
                          // プライバシーモード時は金額を隠す
                          return '支出額: ¥*******'
                        } else {
                          // 通常時は金額を表示（カンマ区切り）
                          return '支出額: ¥' + context.parsed.y.toLocaleString()
                        }
                      }
                    }
                  }
                }
              }
            })
        }

      } catch (error) {
        console.error('チャート更新エラー:', error)
      }
    }

    // === ライフサイクルフック ===
    // コンポーネントがマウントされた時に実行
    onMounted(() => {
      // 利用可能な月データを読み込み、初期データを表示
      loadAvailableMonths()
    })

    // コンポーネントがアンマウントされる前に実行（クリーンアップ）
    onBeforeUnmount(() => {
      // カテゴリ別円グラフのインスタンスを破棄（メモリリーク防止）
      if (categoryChartInstance.value) {
        categoryChartInstance.value.destroy()
      }
      // 日別折れ線グラフのインスタンスを破棄（メモリリーク防止）
      if (dailyChartInstance.value) {
        dailyChartInstance.value.destroy()
      }
    })
    
    return {
      categoryPieChart,
      dailyLineChart,
      chartLegend,
      transactions,
      currentYear,
      currentMonth,
      selectedYear,
      showMonthPicker,
      statsData,
      initialDataLoaded,
      isLoading,
      isNavigating,
      formattedCurrentMonth,
      canGoPrevious,
      canGoNext,
      canGoNextYear,
      canGoPreviousYear,
      hasDataForMonth,
      previousMonth,
      nextMonth,
      previousYear,
      nextYear,
      toggleMonthPicker,
      selectMonth,
      formatCurrency,
      handleCategoryChange,
      updateCharts,
      selectedCategory,
      sortOrder,
      applyFilters,
    }
  }
}
</script>

<style lang="scss" scoped>
.analytics-page {
  
}

.month-navigation {
  background: white;
  border-radius: 10px;
  padding: 20px;
  margin-bottom: 20px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
  position: relative;
}

.nav-controls {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 20px;
  
  // モバイル対応
  @media (max-width: 480px) {
    gap: 10px;
    
    .month-selector {
      min-width: 110px;
      font-size: 0.9em;
    }
  }
}

.nav-btn {
  background: #f8f9fa;
  border: 1px solid #dee2e6;
  border-radius: 50%;
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.3s ease;
  
  &:hover:not(:disabled) {
    background: #4CAF50;
    color: white;
    border-color: #4CAF50;
  }
  
  &:disabled {
    opacity: 0.3;
    cursor: not-allowed;
  }
  
  svg {
    fill: currentColor;
    transition: all 0.3s ease;
  }
  
  .arrow {
    font-size: 1.2em;
    font-weight: bold;
  }
  
  .arrow-double {
    font-size: 1.0em;
    font-weight: bold;
  }
}

.month-selector {
  background: #f8f9fa;
  border: 1px solid #dee2e6;
  border-radius: 8px;
  padding: 10px 15px;
  cursor: pointer;
  user-select: none;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 140px;
  justify-content: space-between;
  
  &:hover {
    background: #e9ecef;
  }
  
  .selected-month {
    font-weight: 600;
  }
  
  .dropdown-arrow {
    font-size: 0.8em;
    color: #6c757d;
    display: flex;
    align-items: center;
    
    svg {
      fill: currentColor;
      transition: transform 0.3s ease;
    }
  }
}

.month-picker {
  position: absolute;
  top: 100%;
  left: 50%;
  transform: translateX(-50%);
  background: white;
  border: 1px solid #dee2e6;
  border-radius: 10px;
  padding: 20px;
  margin-top: 10px;
  box-shadow: 0 4px 20px rgba(0,0,0,0.15);
  z-index: 100;
  min-width: 280px;
}

.year-nav-header {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 15px;
  margin-bottom: 15px;
}

.year-display {
  font-size: 1.1em;
  font-weight: 600;
  color: #333;
  min-width: 80px;
  text-align: center;
}

.year-btn {
  background: #f8f9fa;
  border: 1px solid #dee2e6;
  border-radius: 50%;
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.3s ease;
  
  &:hover:not(:disabled) {
    background: #4CAF50;
    color: white;
    border-color: #4CAF50;
  }
  
  &:disabled {
    opacity: 0.3;
    cursor: not-allowed;
  }
  
  svg {
    fill: currentColor;
    transition: all 0.3s ease;
  }
}

.month-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 10px;
}

.month-item {
  padding: 8px;
  text-align: center;
  border: 1px solid #dee2e6;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.3s ease;
  font-size: 0.9em;
  
  &:hover {
    background: #f8f9fa;
  }
  
  &.has-data {
    background: #e8f5e8;
    border-color: #4CAF50;
    color: #2e7d2e;
    font-weight: 600;
    
    &:hover {
      background: #d4edda;
    }
  }
  
  &.active {
    background: #4CAF50;
    color: white;
    border-color: #4CAF50;
  }
  
  &:not(.has-data) {
    opacity: 0.3;
    cursor: not-allowed;
    background: #f8f9fa;
    color: #999;
    border-color: #e9ecef;
    
    &:hover {
      background: #f8f9fa !important;
      cursor: not-allowed !important;
    }
  }
}

.analytics-page {
  
}

.stats-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 20px;
  margin-bottom: 30px;
  
  // モバイル対応
  @media (max-width: 768px) {
    grid-template-columns: repeat(2, 1fr); // 2列固定
    gap: 15px;
  }
  
  @media (max-width: 480px) {
    grid-template-columns: 1fr; // 1列レイアウト
    gap: 15px;
  }
}

.stat-card {
  background: linear-gradient(135deg, #7dd3fc 0%, #38bdf8 100%);
  color: white;
  padding: 20px;
  border-radius: 10px;
  text-align: center;
  
  &.red {
    background: linear-gradient(135deg, #7dd3fc 0%, #38bdf8 100%);
  }
  
  &.green {
    background: linear-gradient(135deg, #7dd3fc 0%, #38bdf8 100%);
  }
  
  &.orange {
    background: linear-gradient(135deg, #7dd3fc 0%, #38bdf8 100%);
  }
}

.stat-title {
  font-size: 0.9em;
  opacity: 0.9;
  margin-bottom: 10px;
}

.stat-value {
  font-size: 1.8em;
  font-weight: bold;
}

.analytics-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 30px;
  margin-bottom: 30px;
  
  // モバイル対応
  @media (max-width: 768px) {
    grid-template-columns: 1fr; // 1列レイアウト
    gap: 20px;
  }
}

.chart-section {
  background: white;
  border-radius: 10px;
  padding: 25px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}

.chart-title {
  font-size: 1.3em;
  color: #333;
  margin-bottom: 20px;
  padding-bottom: 10px;
  border-bottom: 2px solid #f8f9fa;
}

.chart-container {
  position: relative;
  height: 300px;
  
  .pie-chart-wrapper {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 20px;
    align-items: center;
    height: 100%;
    
    canvas {
      max-width: 200px;
      max-height: 200px;
      margin: 0 auto;
    }
    
    .chart-legend {
      .legend-item {
        display: flex;
        align-items: center;
        margin-bottom: 8px;
        padding: 6px 8px;
        background: #f8f9fa;
        border-radius: 6px;
        transition: background 0.2s ease;
        line-height: 1;
        
        &:hover {
          background: #e9ecef;
        }
        
        .legend-color {
          width: 14px;
          height: 14px;
          border-radius: 3px;
          margin-right: 8px;
          flex-shrink: 0;
          display: inline-block;
          vertical-align: middle;
        }
        
        .legend-text-container {
          flex: 1;
          display: inline-flex;
          justify-content: space-between;
          align-items: center;
          vertical-align: middle;
        }
        
        .legend-label {
          font-weight: 500;
          color: #333;
          font-size: 13px;
        }
        
        .legend-value {
          font-weight: 600;
          color: #666;
          font-size: 12px;
          margin-left: 8px;
        }
      }
    }
    
    // モバイル対応
    @media (max-width: 768px) {
      .pie-chart-wrapper {
        grid-template-columns: 1fr;
        gap: 15px;
        
        canvas {
          max-width: 220px;
          max-height: 220px;
        }
        
        .chart-legend {
          .legend-item {
            margin-bottom: 6px;
            padding: 5px 6px;
            
            .legend-text-container {
              .legend-label {
                font-size: 12px;
              }
              
              .legend-value {
                font-size: 11px;
              }
            }
          }
        }
      }
    }
  }
}

.details-section {
  background: white;
  border-radius: 10px;
  padding: 25px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
  margin-bottom: 30px;
  overflow: visible;
  
  &.full-width {
    grid-column: 1 / -1;
  }
}

.filter-bar {
  display: flex;
  gap: 15px;
  margin-bottom: 20px;
  flex-wrap: wrap;
  
  // モバイル対応
  @media (max-width: 768px) {
    gap: 10px;
    
    .filter-select {
      flex: 1;
      min-width: 120px;
    }
  }
}

.filter-select {
  padding: 8px 15px;
  border: 1px solid #dee2e6;
  border-radius: 5px;
  background: white;
  font-size: 0.9em;
}

.transaction-table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 20px;
  table-layout: fixed; // 固定レイアウトを強制
}

.table-container {
  overflow: visible;
  position: relative;
  
  // モバイル対応
  @media (max-width: 768px) {
    overflow-x: auto; // 横スクロール有効
    
    .transaction-table {
      min-width: 600px; // 最小幅設定
      
      th, td {
        padding: 8px; // パディング調整
        font-size: 0.85em; // フォントサイズ調整
      }
    }
  }
}

.transaction-table th {
  background: #f8f9fa;
  padding: 12px;
  text-align: left;
  border-bottom: 2px solid #dee2e6;
  font-weight: 600;
  
  // 列幅を固定
  &:nth-child(1) { width: 100px; } // 日付
  &:nth-child(2) { width: 200px; } // 店舗・サービス
  &:nth-child(3) { width: 120px; } // カテゴリ
  &:nth-child(4) { width: 100px; } // 金額
}

.transaction-table td {
  padding: 10px 12px;
  border-bottom: 1px solid #dee2e6;
  
  // セル幅を固定（thと同じ）
  &:nth-child(1) { width: 100px; } // 日付
  &:nth-child(2) { 
    width: 200px; // 店舗・サービス
    max-width: 200px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  &:nth-child(3) { width: 120px; } // カテゴリ
  &:nth-child(4) { width: 100px; } // 金額
}

.transaction-table tr:hover {
  background: #f8f9fa;
}

.transaction-table tr {
  position: relative;
}

.amount {
  font-weight: bold;
  text-align: right;
}

.privacy-toggle {
  text-align: center;
  margin-bottom: 20px;
}

</style>