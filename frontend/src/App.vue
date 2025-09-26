<!-- Vue.jsテンプレート部分の開始。Pug（旧Jade）記法を使用して簡潔なHTMLを記述 -->
<template lang="pug">
  // アプリケーション全体のルートコンテナ。IDを「app」に設定してCSSでスタイリング対象とする
  #app
    // メイン画面のコンテナ。最大幅制限、センタリング、影効果を適用するためのクラス
    .container
      // ヘッダーコンポーネントの配置
      // - ナビゲーション機能（ページ遷移）
      // - 現在ページ表示とアクティブ状態制御
      // - プライバシーモード切替機能
      // - アップロード管理モーダル表示機能
      AppHeader(
        @navigate="handleNavigation" 
        :current-page="currentPage"
        :isPrivacyMode="isPrivacyMode"
        @toggle-privacy="togglePrivacyMode"
        @show-upload-manager="showUploadManager = true"
      )
      // メインコンテンツエリア
      // - main要素にcontentクラスを適用してスタイリング
      // - KeepAliveでコンポーネントの状態保持
      // - 動的コンポーネントで各ページを切り替え表示
      main.content
        KeepAlive
          component(
            :is="currentPageComponent"
            :key="currentPage"
            :isPrivacyMode="isPrivacyMode"
            :chartNavigationState="chartNavigationState"
            @navigate="handleNavigation"
            @chart-navigation-updated="handleChartNavigationUpdated"
          )
      // フッターコンポーネント
      // - 著作権表示や補足情報を表示
      AppFooter
    
    // アップロード管理モーダルウィンドウ
    // - CSVファイルのアップロードとバッチ処理を管理
    // - 条件付き表示（showUploadManagerがtrueの場合のみ）
    UploadManager(
      v-if="showUploadManager"
      @close="showUploadManager = false"
      @data-updated="handleDataUpdated"
    )
</template>

<!-- JavaScriptロジック部分。Vue 3のComposition APIを使用したリアクティブな状態管理とイベント処理を定義 -->
<script>
  // Vue 3のリアクティブシステムに必要なref（リアクティブな変数作成）、computed（計算プロパティ）、KeepAlive（コンポーネント状態保持）をインポート
  import { ref, computed, KeepAlive } from 'vue'
  // ヘッダーコンポーネント。ナビゲーション、タイトル表示、プライバシーモード切替ボタンを含む
  import AppHeader from './components/AppHeader.vue'
  // フッターコンポーネント。著作権情報や補足説明を表示
  import AppFooter from './components/AppFooter.vue'
  // ホームページコンポーネント。取引一覧表示、フィルタリング、検索機能を提供
  import HomePage from './components/HomePage.vue'
  // 分析ページコンポーネント。グラフ表示、統計情報、月別・カテゴリ別分析を提供
  import AnalyticsPage from './components/AnalyticsPage.vue'
  // カテゴリルール設定ページコンポーネント。自動カテゴライズルールの作成・編集・削除を管理
  import CategoryRulesPage from './components/CategoryRulesPage.vue'
  // アップロード管理モーダルコンポーネント。CSVファイルの一括アップロード、進捗表示、エラーハンドリングを担当
  import UploadManager from './components/UploadManager.vue'

  // Vue.jsコンポーネントのデフォルトエクスポート。このオブジェクトがコンポーネントの設定を定義
  export default {
    // コンポーネントの識別名。Vue DevToolsでの表示やデバッグ時に使用
    name: 'App',
    // このコンポーネント内で使用する子コンポーネントを登録。テンプレートで使用可能になる
    components: {
      AppHeader,      // ヘッダー部分
      AppFooter,      // フッター部分
      HomePage,       // ホームページ
      AnalyticsPage,  // 分析ページ
      CategoryRulesPage, // カテゴリルールページ
      UploadManager,  // アップロード管理
      KeepAlive      // Vue標準コンポーネント
    },
    // Composition APIのエントリーポイント。このコンポーネントのロジックと状態を定義
    setup() {
      // 現在表示中のページを管理するリアクティブ変数。初期値は'home'（ホームページ）
      const currentPage = ref('home')
      // プライバシーモードのON/OFF状態。trueで金額などの機密情報を「***」で隠す
      const isPrivacyMode = ref(false) // グローバルプライバシーモード
      // アップロード管理モーダルウィンドウの表示/非表示状態。trueで表示
      const showUploadManager = ref(false)
      
      // チャート（グラフ）のナビゲーション機能で使用する共有状態オブジェクト
      const chartNavigationState = ref({
        canGoPrevious: false,  // 前の期間に戻れるかどうか
        canGoNext: false,      // 次の期間に進めるかどうか
        totalMonths: 0,        // 利用可能な総月数
        currentOffset: 0,      // 現在の表示オフセット
        availableMonths: []    // 利用可能な月のリスト
      })
      
      // 計算プロパティ：currentPageの値に基づいて実際に表示するコンポーネント名を動的に決定
      const currentPageComponent = computed(() => {
        // currentPage.valueの値によってコンポーネントを切り替え
        switch (currentPage.value) {
          case 'analytics':
            // 分析ページが選択された場合
            return 'AnalyticsPage'
          case 'category-rules':
            // カテゴリルールページが選択された場合
            return 'CategoryRulesPage'
          default:
            // その他（home等）の場合はホームページを表示
            return 'HomePage'
        }
      })
      
      // ページ遷移を処理する関数。ヘッダーのナビゲーションボタンや子コンポーネントから呼び出される
      const handleNavigation = (page) => {
        // 受け取ったページ名をcurrentPageに設定して画面を切り替える
        currentPage.value = page
      }
      
      // プライバシーモードのON/OFF切り替え関数。ヘッダーのボタンから呼び出される
      const togglePrivacyMode = () => {
        // 現在の状態を反転（true→false、false→true）
        isPrivacyMode.value = !isPrivacyMode.value
      }
      
      // データ更新完了時の処理関数。UploadManagerからCSVアップロード完了時に呼び出される
      const handleDataUpdated = () => {
        // データが更新されたときの処理
        // 必要に応じて他のコンポーネントにデータ再読み込みを促す
        // 現在はコンソールログのみ。将来的にはイベントバスやストアパターンで通知可能
        console.log('Data updated from UploadManager')
      }
      
      // チャートナビゲーション状態更新処理。分析ページのチャートコンポーネントから呼び出される
      const handleChartNavigationUpdated = (state) => {
        // 受け取った状態オブジェクトをchartNavigationStateに設定
        chartNavigationState.value = state
      }
      
      // setup()関数の戻り値。ここで返したオブジェクトがテンプレートで使用可能になる
      return {
        currentPage,                     // 現在のページ状態
        currentPageComponent,            // 表示するコンポーネント名（計算プロパティ）
        isPrivacyMode,                  // プライバシーモード状態
        showUploadManager,              // アップロード管理モーダル表示状態
        chartNavigationState,           // チャートナビゲーション共有状態
        handleNavigation,               // ページ遷移処理関数
        togglePrivacyMode,              // プライバシーモード切り替え関数
        handleDataUpdated,              // データ更新処理関数
        handleChartNavigationUpdated    // チャートナビゲーション状態更新関数
      }
    }
  }
</script>

<!-- SCSS（Sass）を使用したカスケーディングスタイルシート。コンポーネントの見た目とレイアウトを定義 -->
<style lang="scss">
  // 他のSCSSファイルから共通スタイル、変数、ミックスインをインポート。プロジェクト全体のスタイル統一に使用
  @import './styles/main.scss';

  // アプリケーション全体のルートコンテナ（#app要素）に適用するスタイル定義
  #app {
    // システムフォントを優先した読みやすいフォント群。Windows、Mac、Linuxで最適なフォントを自動選択
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    // 対角線グラデーション背景。温かみのある黄色系（#fffbeb→#fef3c7）で135度の角度
    background: linear-gradient(135deg, #fffbeb 0%, #fef3c7 100%);
    // ビューポート高さ100%を最小高さに設定。短いコンテンツでも全画面表示を保証
    min-height: 100vh;
    // 画面端からの余白。モバイルでの見やすさとデスクトップでの美しさを両立
    padding: 20px;
  }

  // メインコンテンツを囲むコンテナ（.container要素）のスタイル定義
  .container {
    // デスクトップ環境での最大幅制限。大画面での横幅広がりすぎを防止
    max-width: 1200px;
    // 左右マージンautoで水平中央寄せ。上下マージンは0
    margin: 0 auto;
    // コンテンツエリアの背景色。白色で清潔感を演出
    background: white;
    // 角丸処理。15pxの半径で現代的で柔らかい印象を作成
    border-radius: 15px;
    // ドロップシャドウ効果。X軸0px、Y軸10px、ぼかし30px、アルファ値0.3の黒で立体感を演出
    box-shadow: 0 10px 30px rgba(0,0,0,0.3);
    // コンテナからはみ出した要素（角丸の外側等）を非表示にして整った外観を維持
    overflow: hidden;
    // フレックスボックスレイアウトを有効化。子要素を柔軟に配置
    display: flex;
    // フレックス方向を縦（列）に設定。ヘッダー→コンテンツ→フッターの順で縦積み
    flex-direction: column;
    // 最小高さを計算値で設定。ビューポート高さからpadding(40px)を引いた値
    min-height: calc(100vh - 40px);
  }

  // メインコンテンツエリア（.content要素）のスタイル定義
  .content {
    // flex: 1でフレックスアイテムとして拡張。利用可能な垂直スペースを全て使用してヘッダーとフッターの間を埋める
    flex: 1;
    // コンテンツ内側の余白。上下左右30pxで読みやすい間隔を確保
    padding: 30px;
  }
</style>