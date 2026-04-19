# Budget Book — Claude Code ガイドライン

## プロジェクト概要

家計簿Webアプリ。楽天カード/エポスカードのCSVを取り込み、カテゴリ別支出を可視化する。

- **バックエンド**: Ruby on Rails (API mode) — `backend/`
- **フロントエンド**: Vue 3 (Composition API, Pug テンプレート, SCSS) — `frontend/`
- **DB**: SQLite

---

## アーキテクチャ早見表

```
frontend/src/
  components/
    HomePage.vue          # CSV アップロード + 月次棒グラフ
    AnalyticsPage.vue     # 月別詳細分析（円グラフ・折れ線・取引テーブル）
    CategoryRulesPage.vue # キーワードルール管理
    UploadManager.vue     # アップロード履歴・削除
    ExpenseChart.vue      # 棒グラフコンポーネント（12ヶ月スクロール）
    SummaryCards.vue      # サマリーカード
    CategoryTag.vue       # カテゴリ変更タグ（インライン編集）
    FileUpload.vue        # ファイルドロップゾーン
  services/api.js         # API 呼び出しをまとめたサービス層

backend/app/
  models/
    category.rb           # カテゴリマスタ（固定7種）
    transaction.rb        # 取引明細
    category_rule.rb      # キーワード→カテゴリ分類ルール（after_save で CSV 自動更新）
    upload_history.rb     # CSVアップロード履歴
  controllers/api/v1/
    transactions_controller.rb   # index / update / import / monthly / analytics
    category_rules_controller.rb # CRUD + bulk_update
    categories_controller.rb
    upload_histories_controller.rb
  services/
    csv_import_service.rb        # CSV パース・インポート（楽天/エポス両対応）
    category_classifier_service.rb
```

---

## カテゴリ定義（変更不可）

| ID | 名前 | 色 | display_order |
|----|------|----|---------------|
| 1 | 投資 | #FF6384 | 1 |
| 2 | 食費 | #4BC0C0 | 2 |
| 3 | 日用品費 | #9966FF | 3 |
| 4 | 娯楽費 | #36A2EB | 4 |
| 5 | 住宅費 | #FF9F40 | 5 |
| 6 | 交通費 | #FFCE56 | 6 |
| 7 | その他 | #C9CBCF | 99 |

カテゴリ名→CSSクラス名マッピング（フロントエンド）:
`投資→investment / 食費→food / 日用品費→daily / 娯楽費→entertainment / 住宅費→housing / 交通費→transport / その他→other`

---

## API エンドポイント

| Method | Path | 説明 |
|--------|------|------|
| GET | /api/v1/transactions | 一覧（?month=YYYY-MM, ?category_id=, ?page=, ?per_page=） |
| PATCH | /api/v1/transactions/:id | カテゴリ更新 |
| POST | /api/v1/transactions/import | CSV インポート |
| GET | /api/v1/transactions/monthly | 月次集計（?year=&month=） |
| GET | /api/v1/transactions/analytics | 詳細分析（?start_date=&end_date=） |
| GET | /api/v1/categories | カテゴリ一覧 |
| GET/POST/PATCH/DELETE | /api/v1/category_rules | ルール CRUD |
| POST | /api/v1/category_rules/bulk_update | キーワード一括更新 |
| GET/DELETE | /api/v1/upload_histories | 履歴管理 |

CORS 許可オリジン: `http://localhost:3002`

---

## デザインシステム

デザイントークンはすべて `frontend/src/styles/variables.scss` で管理。コンポーネント内で直接カラーコードや px 値を書かない。

### カラー
| トークン | 値 | 用途 |
|---|---|---|
| `$color-bg` | `#f0f2f5` | ページ背景 |
| `$color-surface` | `#ffffff` | カード・パネル背景 |
| `$color-surface-sub` | `#f8f9fb` | テーブルヘッダー・サブ背景 |
| `$color-border` | `#e4e7ec` | 区切り線・アウトライン |
| `$color-text-primary` | `#111827` | 見出し・本文 |
| `$color-text-secondary` | `#6b7280` | ラベル・補足 |
| `$color-text-muted` | `#9ca3af` | プレースホルダー・フッター |
| `$color-accent` | `#6366f1` | ボタン・リンク・アクティブ |
| `$color-accent-hover` | `#4f46e5` | ホバー時アクセント |
| `$color-accent-light` | `#eef2ff` | アクセント背景・ホバー背景 |

### スペーシング（4pxグリッド）
`$sp-1`=4px / `$sp-2`=8px / `$sp-3`=12px / `$sp-4`=16px / `$sp-5`=20px / `$sp-6`=24px / `$sp-8`=32px / `$sp-10`=40px

### シャドウ
`$shadow-xs`（カード） / `$shadow-sm`（パネル） / `$shadow-md`（ドロップダウン） / `$shadow-lg`（ドロワー）

### ボーダーラジウス
`$radius-sm`=6px / `$radius-md`=10px / `$radius-lg`=16px / `$radius-full`=9999px

### タイポグラフィ
フォント: `Inter`, `Noto Sans JP`（Google Fonts で読み込み済み）
サイズ: `$font-size-sm`=13px / `$font-size-base`=14px / `$font-size-md`=16px / `$font-size-lg`=18px / `$font-size-xl`=22px
ウェイト: `$font-weight-medium`=500 / `$font-weight-semibold`=600 / `$font-weight-bold`=700

### コンポーネント規則
- カードは `.card` クラス（`$color-surface` + `$radius-lg` + `$shadow-sm` + `$color-border-light` ボーダー）
- プライマリボタン: `$color-accent` 背景・白文字、ホバーで `$color-accent-hover`
- セカンダリボタン: `$color-surface` 背景・`$color-border` ボーダー
- SCSS は `@use "../styles/variables" as *;` で読み込む（`@import` は非推奨）

---

## 開発ルール

### コーディング規約
- **コメント禁止**: 何をするか説明するコメントは書かない。WHY が非自明な場合のみ1行
- **既存スタイル踏襲**: Pug テンプレート・SCSS scoped・Composition API (`setup()`) を統一
- **新ライブラリ追加前**: package.json / Gemfile を必ず確認
- **秘密情報**: ログ出力・コミット禁止

### ファイル操作
- 既存ファイル編集 > 新規作成
- `.md` / `README` は明示指示がない限り作成禁止
- 編集前に必ず Read で現状確認

### CSV 処理の注意点
- BOM 付き UTF-8 / Shift_JIS 両対応（`csv_import_service.rb` 参照）
- 半角カタカナ→全角変換（NKF）でキーワードマッチング精度を維持
- `liberal_parsing: true` 必須

### Rails の注意点
- `belongs_to` は `optional: true` で未分類を許可
- マイグレーション時のインデックス重複に注意
- `category_rule.rb` の after_create/update/destroy フックが CSV を自動更新する

---

## 必須作業

### 毎回の作業後
- `docs/development_diary.md` に実装内容・問題・解決策を記録

### 作業開始時
- TodoWrite でタスクを整理してから着手
- タスク完了次第即 `completed` に更新（バッチ処理禁止）

---

## AI への指示テンプレート

### 機能追加
```
[対象ファイル] frontend/src/components/XXX.vue の [具体的な箇所] に
[何を] 追加してください。
既存の Composition API / Pug / SCSS のスタイルに合わせること。
```

### バグ修正
```
[症状]: ...
[再現手順]: ...
[関連ファイル]: backend/app/controllers/api/v1/transactions_controller.rb
```

### API 追加
```
[エンドポイント]: GET /api/v1/...
[パラメータ]: ...
[レスポンス形式]: { key: value }
transactions_controller.rb に追加し、routes.rb も更新してください。
```
