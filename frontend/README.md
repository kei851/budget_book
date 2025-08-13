# 🎨 Budget Book Frontend

Vue.js 3で構築された楽天カード家計簿アプリのフロントエンド

## ✨ 完成機能

### 📊 データ可視化
- **月次支出グラフ**: Chart.js積み上げ棒グラフ
- **カテゴリ別円グラフ**: 支出割合の可視化  
- **日別推移線グラフ**: 日次支出の推移
- **統計サマリー**: リアルタイム統計表示

### 🎛️ インタラクティブ機能
- **CSVファイルアップロード**: ドラッグ&ドロップ対応
- **月選択ナビゲーション**: 矢印＋クリック選択
- **データがある月のハイライト**: 視認性向上
- **レスポンシブデザイン**: 全デバイス対応

## 🛠️ 技術スタック

- **Vue.js 3** - Composition API
- **Vite** - 高速ビルド・HMR
- **Chart.js** - データビジュアライゼーション
- **Pug** - 簡潔なテンプレート記述
- **SCSS** - CSS拡張・変数管理

## 🚀 開発・起動

```bash
# 依存関係インストール
npm install

# 開発サーバー起動
npm run dev

# 本番ビルド
npm run build

# ビルド結果プレビュー
npm run preview
```

## 📁 ディレクトリ構成

```
src/
├── components/              # Vueコンポーネント
│   ├── HomePage.vue         # メインページ
│   ├── AnalyticsPage.vue    # 詳細分析ページ
│   ├── FileUpload.vue       # CSVアップロード
│   ├── ExpenseChart.vue     # 支出グラフ
│   ├── SummaryCards.vue     # 統計カード
│   ├── CategoryTag.vue      # カテゴリタグ
│   ├── AppHeader.vue        # ヘッダー
│   └── AppFooter.vue        # フッター
├── services/
│   └── api.js              # API通信サービス
├── styles/
│   ├── variables.scss      # SCSS変数
│   └── main.scss          # メインスタイル
├── App.vue                # ルートコンポーネント
└── main.js               # エントリーポイント
```

## 🎨 デザインシステム

### カラーパレット
```scss
$primary-color: #4CAF50;        // メインカラー（緑）
$background-gradient: linear-gradient(135deg, #667eea 0%, #764ba2 100%);

// カテゴリ別色分け
$category-colors: (
  食費: #4BC0C0,
  交通費: #FFCE56,
  日用品費: #9966FF,
  娯楽費: #36A2EB,
  光熱費: #FF9F40,
  その他: #C9CBCF
);
```

### コンポーネントアーキテクチャ
- **Composition API**: リアクティブなデータ管理
- **Props/Emit**: コンポーネント間通信
- **Services**: API通信の分離
- **Single File Components**: コンポーネント単位の開発

## 🔌 API連携

### バックエンド接続
```javascript
// API Base URL
const API_BASE_URL = 'http://localhost:3000/api/v1'

// 主要エンドポイント
- POST /transactions/import    // CSV一括インポート  
- GET  /transactions/monthly   // 月次集計
- GET  /transactions/analytics // 分析データ
- GET  /categories            // カテゴリ一覧
```

### データフロー
```
CSV Upload → API Service → Rails Backend → SQLite → API Response → Vue Components → Chart.js
```

## 📱 レスポンシブ対応

### ブレークポイント
```scss
$mobile: 768px;
$tablet: 1024px;
$desktop: 1200px;
```

### レイアウト
- **モバイル**: 単列レイアウト
- **タブレット**: 2列グリッド
- **デスクトップ**: 3-4列グリッド

## 🧪 開発ツール

### Vite設定
```javascript
// vite.config.js
export default {
  plugins: [vue()],
  css: {
    preprocessorOptions: {
      scss: {
        additionalData: `@import "@/styles/variables.scss";`
      }
    }
  }
}
```

### Hot Module Replacement
- **高速リロード**: ファイル変更の即座反映
- **状態保持**: データ状態の維持
- **CSS HMR**: スタイルの即座更新

## 🎯 パフォーマンス

### 最適化
- **コード分割**: 動的インポート
- **Tree Shaking**: 未使用コード除去
- **Asset最適化**: 画像・フォント最適化
- **Lazy Loading**: コンポーネント遅延読み込み

### ビルドサイズ
```
dist/assets/index-abc123.js   ~45KB (gzipped)
dist/assets/index-def456.css  ~15KB (gzipped)
```

## 🐛 デバッグ・開発

### Vue DevTools対応
- **コンポーネント階層**: 構造の可視化
- **状態管理**: リアクティブデータの監視
- **イベント履歴**: アクション追跡

### エラーハンドリング
```javascript
// グローバルエラーハンドラー
app.config.errorHandler = (err, vm, info) => {
  console.error('Vue Error:', err)
}
```

## 🔜 今後の拡張

### 短期的改善
- [ ] PWA対応（Service Worker）
- [ ] ダークモード対応
- [ ] アニメーション・トランジション強化
- [ ] アクセシビリティ向上

### 中期的発展  
- [ ] TypeScript移行
- [ ] Pinia状態管理導入
- [ ] Storybook導入
- [ ] E2Eテスト（Playwright）

## 📋 ライセンス

MIT License

---

**🎯 目標達成**: 本格的なVue.js SPAとして完成  
**📚 技術習得**: Composition API + Modern Frontend完全理解  
**⚡ パフォーマンス**: 高速・レスポンシブな使用感を実現