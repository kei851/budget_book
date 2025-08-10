# 家計簿アプリ プロジェクト構成

**バージョン**: 1.0  
**作成日**: 2025年8月10日  
**技術スタック**: Vue.js 3 + Pug + SCSS + Rails 7 API + PostgreSQL

## 1. プロジェクト全体構成

```
budget-book/
├── docs/                     # ドキュメント
│   ├── requirements.md       # 要件定義書
│   ├── functional_spec.md    # 機能仕様書
│   ├── technical_spec.md     # 技術設計書
│   └── figma_guide.md        # Figmaデザインガイド
├── frontend/                 # Vue.js フロントエンド
├── backend/                  # Rails API バックエンド
├── design/                   # Figmaファイル・デザイン関連
│   └── README.md
└── README.md                # プロジェクト概要
```

## 2. フロントエンド構成 (Vue.js)

```
frontend/
├── public/
│   ├── index.html
│   └── favicon.ico
├── src/
│   ├── components/           # Vue コンポーネント
│   │   ├── ui/              # 基本UIコンポーネント
│   │   │   ├── BaseButton.vue
│   │   │   ├── BaseCard.vue
│   │   │   ├── BaseInput.vue
│   │   │   └── BaseUpload.vue
│   │   ├── charts/          # グラフコンポーネント
│   │   │   ├── StackedBarChart.vue
│   │   │   └── DoughnutChart.vue
│   │   ├── transaction/     # 取引関連コンポーネント
│   │   │   ├── TransactionList.vue
│   │   │   ├── TransactionItem.vue
│   │   │   ├── CategoryFilter.vue
│   │   │   └── CategoryEditor.vue
│   │   └── layout/          # レイアウトコンポーネント
│   │       ├── AppHeader.vue
│   │       ├── AppFooter.vue
│   │       └── AppSidebar.vue
│   ├── views/               # ページコンポーネント
│   │   ├── HomeView.vue     # メイン画面
│   │   ├── DetailView.vue   # 詳細画面
│   │   ├── LoginView.vue    # ログイン画面（将来）
│   │   └── SettingsView.vue # 設定画面（将来）
│   ├── composables/         # Vue Composition API
│   │   ├── useCsvProcessor.js
│   │   ├── useCategoryClassifier.js
│   │   ├── useTransactionData.js
│   │   └── useAuth.js       # 認証（将来）
│   ├── services/            # API・外部サービス
│   │   ├── api.js           # API基盤
│   │   ├── transactionService.js
│   │   ├── categoryService.js
│   │   └── authService.js   # 認証（将来）
│   ├── utils/               # ユーティリティ
│   │   ├── csvParser.js
│   │   ├── dateFormatter.js
│   │   ├── numberFormatter.js
│   │   └── validators.js
│   ├── stores/              # 状態管理（Pinia）
│   │   ├── transaction.js
│   │   ├── category.js
│   │   └── user.js          # ユーザー状態（将来）
│   ├── styles/              # スタイル
│   │   ├── abstracts/
│   │   │   ├── _variables.scss
│   │   │   ├── _mixins.scss
│   │   │   └── _functions.scss
│   │   ├── base/
│   │   │   ├── _reset.scss
│   │   │   └── _typography.scss
│   │   ├── components/
│   │   │   ├── _buttons.scss
│   │   │   ├── _cards.scss
│   │   │   └── _forms.scss
│   │   ├── layout/
│   │   │   ├── _header.scss
│   │   │   └── _sidebar.scss
│   │   └── main.scss
│   ├── assets/              # 静的ファイル
│   │   ├── images/
│   │   └── icons/
│   ├── router/              # ルーティング
│   │   └── index.js
│   └── main.js              # エントリーポイント
├── package.json
├── vite.config.js
└── README.md
```

## 3. バックエンド構成 (Rails API)

```
backend/
├── app/
│   ├── controllers/
│   │   └── api/
│   │       └── v1/
│   │           ├── application_controller.rb
│   │           ├── transactions_controller.rb
│   │           ├── categories_controller.rb
│   │           ├── users_controller.rb
│   │           ├── sessions_controller.rb      # 認証
│   │           └── registrations_controller.rb # 認証
│   ├── models/
│   │   ├── user.rb
│   │   ├── transaction.rb
│   │   ├── category.rb
│   │   ├── user_category.rb
│   │   ├── user_preference.rb
│   │   └── jwt_denylist.rb    # JWT管理
│   ├── services/
│   │   ├── csv_import_service.rb
│   │   ├── category_classifier_service.rb
│   │   ├── monthly_aggregate_service.rb
│   │   └── transaction_analyzer_service.rb
│   ├── serializers/         # JSON API レスポンス
│   │   ├── transaction_serializer.rb
│   │   ├── category_serializer.rb
│   │   └── user_serializer.rb
│   └── jobs/                # 非同期処理
│       └── csv_import_job.rb
├── config/
│   ├── routes.rb
│   ├── database.yml
│   ├── application.rb
│   └── initializers/
│       ├── cors.rb
│       ├── devise.rb
│       └── jwt.rb
├── db/
│   ├── migrate/
│   │   ├── 001_devise_create_users.rb
│   │   ├── 002_create_categories.rb
│   │   ├── 003_create_transactions.rb
│   │   ├── 004_create_user_categories.rb
│   │   ├── 005_create_user_preferences.rb
│   │   └── 006_create_jwt_denylist.rb
│   ├── seeds.rb
│   └── schema.rb
├── spec/                    # RSpec テスト
│   ├── models/
│   ├── requests/
│   └── services/
├── Gemfile
└── README.md
```

## 4. データベース設計

### 4.1 テーブル構成

```sql
-- users テーブル（Devise）
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  email VARCHAR NOT NULL UNIQUE,
  encrypted_password VARCHAR NOT NULL,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- categories テーブル（カテゴリマスター）
CREATE TABLE categories (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR NOT NULL,
  color VARCHAR(7) NOT NULL,
  icon VARCHAR,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- transactions テーブル（取引明細）
CREATE TABLE transactions (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id),
  category_id BIGINT REFERENCES categories(id),
  date DATE NOT NULL,
  store_name VARCHAR NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  payment_method VARCHAR,
  raw_data JSONB,  -- CSV元データ
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- user_categories テーブル（ユーザーカスタムカテゴリ）
CREATE TABLE user_categories (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id),
  category_id BIGINT REFERENCES categories(id),
  classification_rule TEXT, -- 分類ルール（正規表現等）
  priority INTEGER DEFAULT 0,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- user_preferences テーブル（ユーザー設定）
CREATE TABLE user_preferences (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id),
  display_settings JSONB,  -- 表示設定
  category_colors JSONB,   -- カテゴリ色カスタマイズ
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

### 4.2 インデックス設計

```sql
-- パフォーマンス最適化
CREATE INDEX idx_transactions_user_date ON transactions(user_id, date);
CREATE INDEX idx_transactions_category ON transactions(category_id);
CREATE INDEX idx_transactions_date_range ON transactions(date);
```

## 5. API設計

### 5.1 認証なし（ローカル版）

```
POST /api/v1/transactions/import_csv    # CSV取り込み
GET  /api/v1/transactions               # 取引一覧
GET  /api/v1/transactions/monthly_summary # 月次集計
GET  /api/v1/categories                 # カテゴリ一覧
PUT  /api/v1/transactions/:id           # カテゴリ修正
```

### 5.2 認証あり（将来版）

```
POST /api/v1/signup     # ユーザー登録
POST /api/v1/login      # ログイン
POST /api/v1/logout     # ログアウト

# 以下は認証必須
GET  /api/v1/users/me   # ユーザー情報
PUT  /api/v1/users/me   # ユーザー更新
（上記の取引・カテゴリAPI）
```

## 6. 開発フロー

### Phase 1: 基盤構築
1. Figmaデザイン作成
2. フロントエンド環境構築（Vue + Vite）
3. バックエンド環境構築（Rails API）

### Phase 2: コア機能
4. CSV読み込み・解析機能
5. カテゴリ自動分類機能
6. グラフ表示機能

### Phase 3: UI/UX向上
7. 詳細表示・編集機能
8. レスポンシブ対応
9. エラーハンドリング

### Phase 4: 認証・マルチユーザー
10. ユーザー認証機能
11. データ永続化
12. ユーザー設定機能

## 7. 技術学習ポイント

- **Vue.js**: Composition API、コンポーネント設計
- **Pug**: テンプレート効率化、構造化HTML
- **SCSS**: 変数・mixin、コンポーネント指向CSS
- **Rails**: API設計、認証、サービス層
- **PostgreSQL**: リレーション設計、パフォーマンス
- **Figma**: デザインシステム、プロトタイピング

## 8. デプロイ・運用（将来）

- **フロントエンド**: Vercel / Netlify
- **バックエンド**: Heroku / Railway
- **データベース**: PostgreSQL (Heroku Postgres)
- **CI/CD**: GitHub Actions