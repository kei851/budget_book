# 家計簿アプリ システム設計書

**バージョン**: 1.0  
**作成日**: 2025年8月10日  
**更新日**: 2025年8月10日  

## 1. 設計概要

本設計書は、楽天カードおよびエポスカード明細可視化システムの技術的なシステム設計を定義する。機能仕様書で定義された機能要件を、実際に実装可能な技術アーキテクチャに落とし込んだものである。

### 1.1 システム全体構成

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   フロントエンド   │────│   バックエンド    │────│  データベース    │
│   (Vue.js 3)    │    │  (Rails 7 API)  │    │ (PostgreSQL)    │
│                 │    │                 │    │                 │
│ - UI/UX         │    │ - CSV処理       │    │ - データ永続化   │
│ - グラフ表示    │    │ - API提供       │    │ - 集計処理      │
│ - 状態管理      │    │ - 認証          │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 1.2 開発フェーズ構成

- **Phase 1**: フロントエンドのみ（ブラウザ完結）
- **Phase 2**: バックエンド追加（API連携）
- **Phase 3**: 認証・マルチユーザー対応

## 2. フロントエンド設計

### 2.1 技術スタック

| 分類 | 技術 | バージョン | 用途 |
|------|------|-----------|------|
| フレームワーク | Vue.js | 3.x | メインフレームワーク |
| ビルドツール | Vite | 最新 | 高速ビルド・開発サーバー |
| テンプレート | Pug | 最新 | HTML効率化 |
| スタイル | SCSS/CSS | 最新 | スタイリング |
| 状態管理 | Pinia | 最新 | グローバル状態管理 |
| グラフ | Chart.js | 4.x | グラフ描画 |
| CSV処理 | PapaParse | 最新 | CSVファイル解析 |
| ルーティング | Vue Router | 4.x | SPA ルーティング |

### 2.2 アーキテクチャ構成

```
src/
├── components/           # コンポーネント
│   ├── ui/              # 基本UIコンポーネント
│   ├── charts/          # グラフコンポーネント
│   ├── transaction/     # 取引関連コンポーネント
│   └── layout/          # レイアウトコンポーネント
├── views/               # ページコンポーネント
├── composables/         # Composition API ロジック
├── services/            # APIサービス
├── stores/              # Pinia ストア
├── utils/               # ユーティリティ
└── styles/              # スタイル
```

### 2.3 主要コンポーネント設計

#### 2.3.1 BaseUpload.vue
```javascript
// Props
{
  accept: String,        // ファイル形式
  multiple: Boolean,     // 複数ファイル選択
  maxSize: Number       // 最大ファイルサイズ(MB)
}

// Events
{
  'file-selected': File,
  'file-error': String
}

// 機能
- ドラッグ&ドロップ対応
- ファイル形式・サイズ検証
- プレビュー機能
```

#### 2.3.2 StackedBarChart.vue
```javascript
// Props
{
  data: Object,          // グラフデータ
  period: String,        // 表示期間
  categories: Array      // カテゴリ設定
}

// 機能
- Chart.js統合
- インタラクティブ操作
- レスポンシブ対応
- 期間フィルタリング
```

#### 2.3.3 TransactionList.vue
```javascript
// Props
{
  transactions: Array,   // 取引データ
  pageSize: Number,     // ページサイズ
  filters: Object       // フィルタ条件
}

// 機能
- 仮想スクロール対応
- ソート機能
- フィルタリング
- ページネーション
```

### 2.4 状態管理設計（Pinia）

#### 2.4.1 transactionStore
```javascript
// State
{
  rawData: Array,        // 生のCSVデータ
  transactions: Array,   // 処理済み取引データ  
  monthlyData: Object,   // 月次集計データ
  categories: Array,     // カテゴリ一覧
  filters: Object,       // フィルタ状態
  loading: Boolean,      // ローディング状態
  error: String         // エラー状態
}

// Actions
- importCsvFile()      // CSVファイル読み込み
- classifyCategories() // カテゴリ分類
- aggregateMonthly()   // 月次集計
- updateCategory()     // カテゴリ修正
- applyFilters()       // フィルタ適用
```

#### 2.4.2 uiStore
```javascript
// State  
{
  currentView: String,   // 現在のビュー
  sidebarOpen: Boolean, // サイドバー状態
  theme: String,        // テーマ設定
  displaySettings: Object // 表示設定
}

// Actions
- setCurrentView()
- toggleSidebar()  
- updateSettings()
```

### 2.5 CSV処理設計

#### 2.5.1 csvParser.js
```javascript
// 機能
- BOM付きUTF-8対応
- エンコーディング自動検出
- ヘッダー行検証
- データ型変換
- エラーハンドリング

// メソッド
parseRakutenCsv(file) -> Promise<Array>
validateCsvStructure(data) -> Boolean
convertDataTypes(row) -> Object
```

#### 2.5.2 categoryClassifier.js
```javascript
// 分類ルール
{
  '食費': ['セブンイレブン', 'ローソン', '餃子の王将', ...],
  '交通費': ['JR東日本', '東京メトロ', 'ENEOS', ...],
  '住宅費': ['家賃', '管理費', '修繕費', ...],
  // ...
}

// メソッド
classifyTransaction(storeName) -> String
addCustomRule(category, keywords) -> void
getClassificationAccuracy() -> Number
```

### 2.6 パフォーマンス最適化

#### 2.6.1 大量データ対応
- **仮想スクロール**: 大量な取引明細の表示最適化
- **メモ化**: 計算結果のキャッシュ（computed/memo）
- **チャンク処理**: CSVデータの分割処理
- **Web Workers**: CPU集約的処理の分離（将来）

#### 2.6.2 レンダリング最適化
- **遅延読み込み**: コンポーネントの動的インポート
- **画像最適化**: SVGアイコン使用
- **バンドル分割**: コード分割による初期ロード高速化

## 3. バックエンド設計（Phase 2以降）

### 3.1 技術スタック

| 分野 | 技術 | バージョン | 用途 |
|------|------|-----------|------|
| フレームワーク | Ruby on Rails | 7.x | API サーバー |
| データベース | PostgreSQL | 15+ | データ永続化 |
| 認証 | Devise + JWT | 最新 | ユーザー認証 |
| CSV処理 | Ruby CSV | 標準 | CSV処理エンジン |
| 非同期処理 | Sidekiq | 最新 | バックグラウンドジョブ |
| API | JSON:API | 標準 | RESTful API |

### 3.2 データベース設計

#### 3.2.1 ER図
```
users 1────n transactions n────1 categories
  │                               │
  └─── 1────n user_categories ────┘
  │
  └─── 1────1 user_preferences
```

#### 3.2.2 テーブル設計詳細

**users テーブル**
```sql
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  encrypted_password VARCHAR(255) NOT NULL,
  first_name VARCHAR(100),
  last_name VARCHAR(100),  
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

**transactions テーブル**
```sql
CREATE TABLE transactions (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category_id BIGINT REFERENCES categories(id),
  transaction_date DATE NOT NULL,
  store_name VARCHAR(500) NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  payment_method VARCHAR(100),
  user_name VARCHAR(100),
  payment_month VARCHAR(50),
  raw_data JSONB,  -- 元のCSVデータ
  auto_classified BOOLEAN DEFAULT true,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

-- インデックス
CREATE INDEX idx_transactions_user_date ON transactions(user_id, transaction_date);
CREATE INDEX idx_transactions_category ON transactions(category_id);
CREATE INDEX idx_transactions_amount ON transactions(amount);
CREATE INDEX idx_transactions_store ON transactions USING gin(to_tsvector('japanese', store_name));
```

**categories テーブル**
```sql
CREATE TABLE categories (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  color VARCHAR(7) NOT NULL, -- HEX色コード
  icon VARCHAR(50),
  description TEXT,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

**user_categories テーブル**（ユーザー独自ルール）
```sql
CREATE TABLE user_categories (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category_id BIGINT NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  classification_rule TEXT NOT NULL, -- 正規表現パターン
  rule_type VARCHAR(50) NOT NULL,    -- 'keyword', 'regex', 'exact'
  priority INTEGER DEFAULT 0,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

**user_preferences テーブル**
```sql
CREATE TABLE user_preferences (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  display_settings JSONB DEFAULT '{}',
  category_colors JSONB DEFAULT '{}',
  notification_settings JSONB DEFAULT '{}',
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

### 3.3 API設計

#### 3.3.1 認証API
```
POST /api/v1/auth/signup          # ユーザー登録
POST /api/v1/auth/login           # ログイン
POST /api/v1/auth/logout          # ログアウト
POST /api/v1/auth/refresh         # トークン更新
```

#### 3.3.2 取引データAPI
```
POST /api/v1/transactions/import    # CSV一括インポート
GET  /api/v1/transactions           # 取引一覧取得
PUT  /api/v1/transactions/:id       # 取引更新（カテゴリ等）
DELETE /api/v1/transactions/:id     # 取引削除

GET  /api/v1/transactions/monthly_summary    # 月次集計データ
GET  /api/v1/transactions/category_summary   # カテゴリ別集計
GET  /api/v1/transactions/stats             # 統計データ
```

#### 3.3.3 カテゴリAPI
```
GET  /api/v1/categories             # カテゴリ一覧
POST /api/v1/categories             # カテゴリ作成
PUT  /api/v1/categories/:id         # カテゴリ更新  
DELETE /api/v1/categories/:id       # カテゴリ削除

GET  /api/v1/user_categories        # ユーザー独自ルール一覧
POST /api/v1/user_categories        # ルール作成
PUT  /api/v1/user_categories/:id    # ルール更新
DELETE /api/v1/user_categories/:id  # ルール削除
```

### 3.4 サービス層設計

#### 3.4.1 CsvImportService
```ruby
class CsvImportService
  def initialize(user, csv_file)
    @user = user
    @csv_file = csv_file
  end

  def import
    # CSVファイル解析
    parsed_data = parse_csv(@csv_file)
    
    # カテゴリ自動分類
    classified_data = classify_categories(parsed_data)
    
    # データベース保存
    save_transactions(classified_data)
    
    # 結果返却
    ImportResult.new(success: true, count: classified_data.size)
  end

  private

  def parse_csv(file)
    # エンコーディング検出・変換
    # ヘッダー検証
    # データ変換
  end

  def classify_categories(data)
    # 自動分類ロジック
  end
end
```

#### 3.4.2 CategoryClassifierService
```ruby
class CategoryClassifierService
  CLASSIFICATION_RULES = {
    '食費' => [
      /セブンイレブン|ローソン|ファミマ/i,
      /スーパー|マーケット/i,
      /餃子の王将|マクドナルド|スタバ/i
    ],
    '交通費' => [
      /JR|私鉄|地下鉄/i,
      /ENEOS|Shell|昭和シェル/i,
      /タクシー|バス/i
    ]
  }.freeze

  def classify(store_name)
    # ユーザー独自ルール優先
    user_category = check_user_rules(store_name)
    return user_category if user_category

    # デフォルトルール適用
    check_default_rules(store_name)
  end
end
```

#### 3.4.3 MonthlyAggregateService
```ruby
class MonthlyAggregateService
  def initialize(user, start_date, end_date)
    @user = user
    @start_date = start_date
    @end_date = end_date
  end

  def aggregate
    transactions = @user.transactions
                       .includes(:category)
                       .where(transaction_date: @start_date..@end_date)

    # 月次・カテゴリ別集計
    monthly_data = transactions
      .group("DATE_TRUNC('month', transaction_date)")
      .group(:category_id)
      .sum(:amount)

    format_response(monthly_data)
  end
end
```

### 3.5 認証・セキュリティ設計

#### 3.5.1 JWT認証フロー
```
1. ユーザーログイン → JWT発行
2. フロントエンドでJWTをlocalStorageに保存
3. API リクエスト時に Authorization ヘッダーで送信
4. バックエンドでJWT検証・ユーザー認証
5. トークン有効期限管理・リフレッシュ
```

#### 3.5.2 セキュリティ対策
- **CORS設定**: フロントエンドドメインのみ許可
- **HTTPS強制**: 本番環境での暗号化通信
- **SQL インジェクション**: ActiveRecord ORM使用
- **XSS対策**: JSON レスポンスのサニタイズ
- **認可制御**: ユーザーごとのデータアクセス制限

## 4. インフラ・デプロイ設計

### 4.1 開発環境
- **フロントエンド**: Vite dev server (localhost:3000)
- **バックエンド**: Rails server (localhost:3001)  
- **データベース**: PostgreSQL (Docker)
- **バージョン管理**: Git + GitHub

### 4.2 本番環境（将来）
- **フロントエンド**: Vercel / Netlify
- **バックエンド**: Railway / Heroku
- **データベース**: PostgreSQL (managed service)
- **CDN**: Cloudflare (静的ファイル配信)

### 4.3 CI/CD パイプライン
```yaml
# GitHub Actions
name: CI/CD Pipeline

on: [push, pull_request]

jobs:
  frontend-test:
    - Vue.js テスト実行
    - ビルド確認
    
  backend-test:
    - RSpec テスト実行
    - Rubocop コード品質確認
    
  deploy:
    - フロントエンド → Vercel
    - バックエンド → Railway
```

## 5. パフォーマンス・スケーラビリティ

### 5.1 パフォーマンス要件
- **CSV処理**: 50MB（50万件）を30秒以内
- **API レスポンス**: 平均500ms以内
- **グラフ描画**: 5秒以内
- **メモリ使用量**: 1GB以内

### 5.2 最適化手法
- **データベース**: インデックス最適化、クエリ最適化
- **API**: ページネーション、レスポンス キャッシュ
- **フロントエンド**: コード分割、遅延読み込み
- **CSV処理**: ストリーミング処理、チャンク分割

### 5.3 将来のスケーラビリティ
- **水平スケール**: ロードバランサー + 複数インスタンス
- **データ分割**: ユーザーごと・期間ごとのパーティショニング
- **キャッシュ**: Redis導入でAPI キャッシュ
- **非同期処理**: Sidekiq導入で重い処理の非同期化

## 6. テスト設計

### 6.1 フロントエンドテスト
- **Unit Test**: Vue Test Utils + Vitest
- **Integration Test**: コンポーネント間連携テスト
- **E2E Test**: Playwright (将来)

### 6.2 バックエンドテスト  
- **Unit Test**: RSpec (モデル・サービス)
- **Integration Test**: Request specs (API)
- **Performance Test**: CSV処理性能テスト

### 6.3 テストカバレッジ目標
- **フロントエンド**: 70%以上
- **バックエンド**: 85%以上
- **重要機能**: 100%（CSV処理、認証）

## 7. 監視・運用設計

### 7.1 ログ設計
- **アプリケーションログ**: Rails logger
- **アクセスログ**: Nginx/Apache
- **エラー監視**: Sentry (将来)

### 7.2 メトリクス収集
- **パフォーマンス**: レスポンス時間、スループット
- **ビジネス**: CSV処理成功率、ユーザー活動
- **インフラ**: CPU、メモリ、ディスク使用率

### 7.3 バックアップ・災害対策
- **データベース**: 日次フルバックアップ + 継続的アーカイブ
- **ファイル**: ユーザーアップロードファイルの S3 保存
- **コード**: Git リポジトリの複数拠点管理

## 8. セキュリティ設計

### 8.1 データ保護
- **個人情報**: 金融データの暗号化保存
- **通信**: HTTPS/TLS 1.3
- **ファイル**: アップロードファイルのウイルススキャン

### 8.2 認証・認可
- **パスワード**: bcrypt ハッシュ化
- **セッション**: JWT + リフレッシュトークン
- **API**: トークンベース認証

### 8.3 脆弱性対策
- **依存関係**: 定期的な脆弱性スキャン
- **コード**: 静的解析ツール導入
- **ペネトレーション**: セキュリティ監査（本格運用時）

## 9. 品質保証

### 9.1 コード品質
- **Linting**: ESLint (JS) + RuboCop (Ruby)
- **Formatting**: Prettier (JS) + RuboCop (Ruby)  
- **コードレビュー**: GitHub Pull Request
- **型安全性**: TypeScript導入検討

### 9.2 ドキュメント品質
- **API仕様**: OpenAPI/Swagger
- **コード**: JSDoc + YARD
- **運用**: Runbook作成

## 10. 移行・リリース戦略

### 10.1 段階的リリース
1. **Phase 1**: フロントエンドのみ（ローカル処理）
2. **Phase 2**: バックエンド API 追加
3. **Phase 3**: 認証・マルチユーザー対応

### 10.2 データ移行
- **Phase 1→2**: ローカルデータ → API経由保存
- **設定移行**: ユーザー設定の引き継ぎ機能
- **バックアップ**: 移行前後のデータ整合性確認

### 10.3 ロールバック計画
- **データベース**: マイグレーション ロールバック
- **アプリケーション**: 前バージョンへの切り戻し
- **データ**: バックアップからの復旧手順

## 11. 運用・保守設計

### 11.1 定期メンテナンス
- **月次**: 依存関係アップデート
- **四半期**: セキュリティパッチ適用
- **半年**: 大型機能追加・改修

### 11.2 障害対応
- **監視**: 24時間システム監視設定
- **通知**: 重要アラートの自動通知  
- **対応**: エスカレーション手順書

### 11.3 成長・改善
- **ユーザーフィードバック**: 利用データ分析
- **機能改善**: A/B テスト実施
- **技術負債**: 定期的なリファクタリング