# 家計簿アプリ 学習計画・技術提案

## 1. 学習目標に合わせた技術構成

### 1.1 推奨技術スタック
- **デザイン**: Figma
- **フロントエンド**: Vue.js 3 + JavaScript
- **テンプレート**: Pug (Pugライブラリ使用)
- **スタイル**: SCSS
- **バックエンド**: Ruby on Rails 7 (API モード + 認証機能)
- **認証**: Devise + JWT (将来対応)
- **データベース**: PostgreSQL (本番) / SQLite (開発)
- **ビルドツール**: Vite

### 1.2 この構成のメリット
1. **Figma**: デザインシステム、コンポーネント設計の学習
2. **Vue.js**: モダンフレームワークの基本概念習得
3. **Pug**: HTMLテンプレートの効率的な書き方
4. **SCSS**: CSS設計手法、変数、mixin等の活用
5. **Rails API**: RESTful API設計、MVC アーキテクチャ
6. **JavaScript**: ES6+、非同期処理、DOM操作

## 2. フェーズ別学習アプローチ

### Phase 1: デザイン・設計 (1-2週間)
**学習内容**:
- Figmaでのコンポーネント設計
- デザインシステム構築
- ユーザー体験設計

**成果物**:
- Figmaデザインファイル
- デザインシステム
- プロトタイプ

### Phase 2: フロントエンド基盤 (2-3週間)  
**学習内容**:
- Vue.js 3の基本概念（Composition API）
- Pug テンプレート記法
- SCSS による スタイル設計
- Vite 設定とビルドプロセス

**成果物**:
- Vue.js プロジェクト構築
- 基本コンポーネント実装
- レスポンシブ デザイン

### Phase 3: データ処理・可視化 (2-3週間)
**学習内容**:
- JavaScript ES6+ (非同期処理、モジュール)
- CSV ファイル処理
- Chart.js によるデータ可視化
- Vue.js の状態管理

**成果物**:
- CSV読み込み機能
- グラフ表示機能
- カテゴリ分類機能

### Phase 4: バックエンドAPI + 認証 (3-4週間)
**学習内容**:
- Ruby on Rails 7 API モード
- RESTful API 設計
- データベース設計 (PostgreSQL)
- 認証システム (Devise + JWT)
- ユーザー管理・セッション管理
- CORS設定・セキュリティ

**成果物**:
- Rails API サーバー
- ユーザー認証システム
- データベース設計（マルチユーザー対応）
- API エンドポイント

### Phase 5: 統合・最適化 (1-2週間)
**学習内容**:
- フロントエンド・バックエンド統合
- パフォーマンス最適化
- エラーハンドリング
- デプロイメント

**成果物**:
- 完全動作アプリケーション
- デプロイ環境構築

## 3. 具体的な学習提案

### 3.1 Figma活用提案

**デザインシステム構築**:
```
Design System/
├── 🎨 Foundation
│   ├── Colors (カテゴリ色、UI色)
│   ├── Typography (見出し、本文)
│   └── Spacing (8px グリッド)
├── 🧩 Components
│   ├── Button (Primary, Secondary)
│   ├── Card (Stat, Info)  
│   ├── Input (Search, Dropdown)
│   └── Chart (Bar, Doughnut プレースホルダー)
└── 📱 Responsive
    ├── Desktop (1440px)
    ├── Tablet (768px)
    └── Mobile (375px)
```

### 3.2 Vue.js + Pug + SCSS 構成

**ディレクトリ構造**:
```
src/
├── components/
│   ├── ui/
│   │   ├── BaseButton.vue (Pug + SCSS)
│   │   ├── BaseCard.vue  
│   │   └── BaseInput.vue
│   ├── charts/
│   │   ├── StackedBarChart.vue
│   │   └── DoughnutChart.vue
│   └── layout/
│       ├── AppHeader.vue
│       └── AppFooter.vue
├── views/
│   ├── HomeView.vue (メイン画面)
│   └── DetailView.vue (詳細画面)
├── styles/
│   ├── _variables.scss (色、フォント定義)
│   ├── _mixins.scss (共通スタイル)
│   └── main.scss
└── utils/
    ├── csvProcessor.js
    └── categoryClassifier.js
```

### 3.3 Rails API 設計（認証対応）

**API エンドポイント例**:
```ruby
# routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # 認証関連
      devise_for :users, path: '', path_names: {
        sign_in: 'login',
        sign_out: 'logout',
        registration: 'signup'
      }, controllers: {
        sessions: 'api/v1/sessions',
        registrations: 'api/v1/registrations'
      }
      
      # ユーザー認証が必要なルート
      resources :transactions, only: [:index, :create, :update, :destroy] do
        collection do
          post :import_csv
          get :monthly_summary
          get :category_breakdown
        end
      end
      
      resources :categories, only: [:index, :update]
      
      # ユーザー設定
      resources :users, only: [:show, :update] do
        member do
          get :preferences
          put :update_preferences
        end
      end
    end
  end
end
```

**データベース設計（マルチユーザー対応）**:
```ruby
# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist
         
  has_many :transactions, dependent: :destroy
  has_many :user_categories, dependent: :destroy
  has_one :user_preference, dependent: :destroy
end

# app/models/transaction.rb
class Transaction < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true
  
  validates :date, :store_name, :amount, presence: true
  scope :by_month, ->(month) { where(date: month.beginning_of_month..month.end_of_month) }
end

# app/models/category.rb  
class Category < ApplicationRecord
  has_many :transactions
  has_many :user_categories
  
  validates :name, :color, presence: true
end

# app/models/user_category.rb (ユーザー独自カテゴリ)
class UserCategory < ApplicationRecord
  belongs_to :user
  belongs_to :category
  
  # カスタム分類ルール
  validates :classification_rule, presence: true
end
```

### 3.4 学習効果を最大化する実装順序

1. **静的プロトタイプ**: Figma → Vue + Pug + SCSS
2. **データ可視化**: Chart.js 統合、JavaScript ES6+
3. **CSV処理**: ファイル読み込み、パース、分類
4. **API開発**: Rails でデータ永続化
5. **統合テスト**: フロント・バック連携

## 4. 各技術の学習ポイント

### 4.1 Figma
- **コンポーネント化**: 再利用可能なUI部品
- **Auto Layout**: レスポンシブ対応
- **Variants**: 状態管理（ホバー、アクティブ等）
- **Design Tokens**: 開発との連携

### 4.2 Vue.js + Pug
```vue
<template lang="pug">
.transaction-list
  .list-header
    h2.list-title 取引明細 ({{ transactions.length }}件)
    .list-total ¥{{ totalAmount.toLocaleString() }}
  
  .list-body
    transaction-item(
      v-for="transaction in paginatedTransactions"
      :key="transaction.id"
      :transaction="transaction"
      @update-category="updateCategory"
    )
</template>

<style lang="scss" scoped>
.transaction-list {
  background: $white;
  border-radius: $border-radius-lg;
  box-shadow: $shadow-sm;
  
  .list-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: $spacing-lg;
    border-bottom: 1px solid $border-color;
  }
}
</style>
```

### 4.3 SCSS 設計
```scss
// _variables.scss
$primary-color: #4CAF50;
$category-colors: (
  'food': #4BC0C0,
  'transport': #FFCE56,
  'housing': #FF6B6B,
  'entertainment': #36A2EB,
);

// _mixins.scss  
@mixin card-style {
  background: white;
  border-radius: 10px;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
  padding: 20px;
}

@mixin category-color($category) {
  background-color: map-get($category-colors, $category);
}
```

### 4.4 Rails API
```ruby
# controllers/api/v1/transactions_controller.rb
class Api::V1::TransactionsController < ApplicationController
  def import_csv
    file = params[:file]
    transactions = CsvImportService.new(file).call
    
    render json: {
      success: true,
      transactions: transactions,
      summary: MonthlyAggregateService.new(transactions).call
    }
  rescue CsvImportService::InvalidFileError => e
    render json: { error: e.message }, status: 422
  end
end
```

## 5. 学習リソース

### 5.1 公式ドキュメント
- Vue.js: https://vuejs.org/guide/
- Pug: https://pugjs.org/api/getting-started.html
- SCSS: https://sass-lang.com/guide
- Rails: https://guides.rubyonrails.org/

### 5.2 学習コンテンツ
- Vue.js チュートリアル
- SCSS実践ガイド
- Rails API開発ガイド
- Chart.js 公式サンプル

## 6. プロジェクト完成後の発展

1. **TypeScript移行**: JavaScript → TypeScript
2. **状態管理**: Pinia導入
3. **テスト**: Vitest + Testing Library
4. **CI/CD**: GitHub Actions
5. **インフラ**: Docker + AWS/Heroku

このアプローチで、実用的なアプリケーションを作りながら、各技術を体系的に学習できます！