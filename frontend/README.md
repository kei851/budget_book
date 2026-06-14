# Frontend

Vue 3 + Vite による家計簿アプリのフロントエンド。

## 起動

```bash
npm install
npm run dev   # http://localhost:3002
```

## 構成

```
src/
├── components/
│   ├── HomePage.vue             # CSV取込・月次棒グラフ
│   ├── AnalyticsPage.vue        # 詳細分析（概要/インサイト/取引明細タブ）
│   ├── AssetPage.vue            # 資産管理（月次残高・推移グラフ）
│   ├── CategoryRulesPage.vue    # キーワード分類ルール管理
│   ├── AiChatPanel.vue          # AIチャット（右下フローティング）
│   ├── NavSidebar.vue           # 左サイドバーナビゲーション
│   ├── AiSummaryCard.vue        # AIサマリカード
│   ├── BudgetCard.vue           # 月次予算カード
│   ├── MonthlyComparisonCard.vue # 前月比較カード
│   ├── RecurringCard.vue        # 定期支出カード
│   ├── CategoryTag.vue          # インラインカテゴリ変更タグ
│   ├── ExpenseChart.vue         # 月次棒グラフ（12ヶ月スクロール）
│   ├── FileUpload.vue           # CSVドロップゾーン
│   ├── UploadManager.vue        # アップロード履歴・削除
│   └── AppFooter.vue
├── services/
│   └── api.js                   # バックエンドAPI呼び出しをまとめた層
├── styles/
│   ├── variables.scss           # デザイントークン（色・スペーシング等）
│   └── main.scss                # グローバルスタイル
├── App.vue                      # ルートコンポーネント・ルーティング
└── main.js
```

## 技術

- Vue 3 Composition API（`setup()` + `ref` / `computed`）
- Pug テンプレート
- SCSS（`variables.scss` は vite.config.js の `additionalData` で全コンポーネントに自動注入）
- Chart.js（棒グラフ・円グラフ・折れ線グラフ）
- Vite

## デザインシステム

デザイントークンはすべて `styles/variables.scss` で管理。コンポーネント内に直接カラーコードや px 値を書かない。
