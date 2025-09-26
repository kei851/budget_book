# 📚 Budget Book コード読解ガイド

**作成日**: 2025 年 9 月 1 日  
**目的**: ソースコードを一行レベルで完璧に理解するための学習ガイド

---

## 🏗️ アーキテクチャ全体像

Budget Book は **Vue.js（フロントエンド）+ Rails API（バックエンド）** のフルスタック構成です。

### 技術スタック

- **フロントエンド**: Vue.js 3 + Vite + Chart.js + SCSS + Pug
- **バックエンド**: Rails 8 API + SQLite + CSV 処理
- **通信**: REST API + CORS 対応

### データフロー

```
CSVファイル → Rails（csv_import_service.rb）→ SQLite → API → Vue.js → Chart.js表示
```

---

## 🎯 最適なコード読解順序

### 📋 Phase 1: データモデル理解（バックエンド基盤）

まず、データの構造を理解することが重要です。

1. **[application_record.rb](../backend/app/models/application_record.rb)** - Rails 基底クラス

   - ActiveRecord の基本設定を確認

2. **[category.rb](../backend/app/models/category.rb)** - カテゴリマスタ

   - カテゴリの定義とリレーション
   - `has_many :transactions`の関係性

3. **[transaction.rb](../backend/app/models/transaction.rb)** - 取引データ（メインエンティティ）

   - メインのビジネスデータ
   - `belongs_to :category`の関係性
   - バリデーションルール

4. **[category_rule.rb](../backend/app/models/category_rule.rb)** - カテゴリ分類ルール

   - 自動分類のためのルール定義

5. **[upload_history.rb](../backend/app/models/upload_history.rb)** - アップロード履歴
   - ファイル処理の履歴管理

### ⚙️ Phase 2: ビジネスロジック（コア機能）

データ処理の心臓部です。

6. **[csv_import_service.rb](../backend/app/services/csv_import_service.rb)** - CSV 解析・インポート処理

   - **最重要ファイル**: CSV の解析・文字エンコーディング処理
   - `perform`メソッドから読み始める
   - エラーハンドリングパターンを理解

7. **[category_classifier_service.rb](../backend/app/services/category_classifier_service.rb)** - 自動カテゴリ分類
   - 店舗名による自動分類ロジック
   - 半角カタカナ → 全角カタカナ変換処理

### 🌐 Phase 3: API 層（データ提供）

フロントエンドとの橋渡し部分です。

8. **[application_controller.rb](../backend/app/controllers/application_controller.rb)** - API 基底

   - CORS 設定やエラーハンドリングの基盤

9. **[transactions_controller.rb](../backend/app/controllers/api/v1/transactions_controller.rb)** - メイン API

   - **重要**: `import`, `monthly`, `analytics`メソッド
   - データ集計・JSON 変換処理

10. **[categories_controller.rb](../backend/app/controllers/api/v1/categories_controller.rb)** - カテゴリ API

    - カテゴリ一覧の提供

11. **[routes.rb](../backend/config/routes.rb)** - ルーティング定義
    - API 構造の全体像を把握

### 🎨 Phase 4: フロントエンド基盤

Vue.js アプリケーションの基礎です。

12. **[main.js](../frontend/src/main.js)** - Vue.js エントリーポイント

    - アプリケーション初期化

13. **[App.vue](../frontend/src/App.vue)** - メインアプリコンポーネント

    - SPA 全体の構造
    - ルーティングとレイアウト

14. **[api.js](../frontend/src/services/api.js)** - API 通信層
    - バックエンドとの通信処理
    - HTTP クライアント設定

### 🖼️ Phase 5: UI コンポーネント（表示層）

ユーザーが見る画面の実装です。

15. **[HomePage.vue](../frontend/src/components/HomePage.vue)** - ホーム画面

    - アプリケーションのメイン画面

16. **[FileUpload.vue](../frontend/src/components/FileUpload.vue)** - CSV アップロード

    - ファイルアップロード処理
    - ドラッグ&ドロップ実装

17. **[ExpenseChart.vue](../frontend/src/components/ExpenseChart.vue)** - Chart.js 可視化

    - **重要**: グラフ表示ロジック
    - Chart.js の設定とデータバインディング

18. **[AnalyticsPage.vue](../frontend/src/components/AnalyticsPage.vue)** - 詳細分析画面
    - 月次分析・統計表示

### ⚙️ Phase 6: 設定・補助機能

システムの設定やサポート機能です。

19. **[データベースマイグレーション](../backend/db/migrate/)** - データベース構造

    - テーブル定義とインデックス設計

20. **[vite.config.js](../frontend/vite.config.js)** - ビルド設定

    - フロントエンドビルド設定

21. **[CORS 設定](../backend/config/initializers/cors.rb)** - CORS 設定
    - フロントエンド・バックエンド間通信設定

---

## 🔑 重要なデータフローとコード箇所

### CSV インポート処理

```ruby
# backend/app/services/csv_import_service.rb:50-120
def perform
  # エンコーディング判定・変換
  # CSV解析
  # データベース保存
end
```

### カテゴリ自動分類

```ruby
# backend/app/services/category_classifier_service.rb:15-45
def classify_transaction(store_name)
  # 店舗名正規化
  # ルールマッチング
  # カテゴリ決定
end
```

### API 集計処理

```ruby
# backend/app/controllers/api/v1/transactions_controller.rb:45-80
def monthly
  # 月次データ集計
  # JSON変換
end
```

### フロントエンド可視化

```vue
<!-- frontend/src/components/ExpenseChart.vue:80-150 -->
<script>
// Chart.js設定
// データ更新処理
// レスポンシブ対応
</script>
```

---

## 📝 学習のコツ

### 1. データの流れを追う

- CSV ファイル → データベース → API → 画面表示
- この流れに沿って読むと理解しやすい

### 2. 重要なメソッドを特定

- `csv_import_service.rb`の`perform`メソッド
- `transactions_controller.rb`の集計メソッド群
- Vue コンポーネントの`mounted`と`methods`

### 3. エラーハンドリングに注目

- CSV 処理での文字エンコーディング対応
- API 通信でのエラーレスポンス処理
- フロントエンドでのローディング状態管理

### 4. 設定ファイルも重要

- CORS 設定（`backend/config/initializers/cors.rb`）
- データベース設定（`backend/config/database.yml`）
- Vite 設定（`frontend/vite.config.js`）

---

## 🔗 関連ドキュメント

- **[要件定義書](./requirement_definition.md)** - 機能要件の詳細
- **[システム設計書](./system_design.md)** - アーキテクチャ設計
- **[開発日誌](./development_diary.md)** - 実装履歴と技術的知見
- **[機能仕様書](./functional_spec.md)** - 詳細仕様

---

## 🚀 効率的なコメント作業戦略

### 📊 作業量削減の分析結果

**全体コード量**: 11,797行 → **効率化後**: 2,500行（**79%削減**）

### 🎯 重複パターン別削減戦略

#### 1. CRUD Controllers（70%削減可能）
- **代表ファイル**: `transactions_controller.rb`（286行）を詳細理解
- **スキップ対象**: `categories_controller.rb`（9行）、`category_rules_controller.rb`（113行）
- **理由**: 基本的なCRUD構造は共通、ビジネスロジック部分のみ重要

#### 2. Vue Components（60%削減可能）
- **重要コンポーネント**: `AnalyticsPage.vue`（1339行）、`ExpenseChart.vue`
- **パターン理解後スキップ**: `SummaryCards.vue`、基本的なフォーム処理
- **理由**: template構造、API通信パターンが類似

#### 3. Migration Files（80%削減可能）
- **代表ファイル**: 2-3個の基本パターンを理解
- **スキップ対象**: 定型的なadd_column、create_table
- **理由**: DDL構文は繰り返しパターン

#### 4. 設定・定型ファイル（90%削減可能）
- **重要**: CORS設定、routing設定
- **スキップ対象**: import文、基本的な設定値
- **理由**: 一度理解すれば応用可能

### ⏱️ 新しい時間見積もり

**従来**: 98時間 → **効率化後**: 31時間（実質1-2週間）

- **詳細理解必要**: 2,500行 × 60秒 = 25時間
- **パターン確認**: 残り × 10秒 = 6時間
- **合計**: 約31時間

### 📋 学習優先度マトリクス

| ファイル種別 | 学習価値 | 削減率 | 対応方針 |
|--------------|----------|--------|----------|
| メインビジネスロジック | ★★★★★ | 10% | 全行詳細理解 |
| API Controllers | ★★★★☆ | 30% | 主要メソッドのみ |
| Vue Components | ★★★☆☆ | 60% | 代表的なパターンのみ |
| Migration/Config | ★★☆☆☆ | 80% | 基本構造のみ |
| Import/定型文 | ★☆☆☆☆ | 90% | ほぼスキップ |

---

## 💡 実践的な読み方

### 初回学習時

1. README.md でプロジェクト全体を把握
2. このガイドの順序でコードを読む
3. 不明な部分は開発日誌で背景を確認

### 復習時

1. データモデル（Phase 1）から復習
2. 前回理解できなかった箇所を重点的に
3. 新しい発見があれば開発日誌に記録

### 機能追加時

1. 該当する機能のコードを特定
2. 関連するファイルを横断的に確認
3. データフローを意識して実装

---

**🎯 目標**: このガイドを使って、Budget Book の全コードを完璧に理解し、機能追加・改修を自由自在に行えるようになる

**📚 学習成果**: フルスタック Web アプリケーションの実装パターンとベストプラクティスの習得
