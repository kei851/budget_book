# 拡張計画 - システム統合用

**バージョン**: 1.0  
**作成日**: 2025 年 10 月 31 日  
**更新日**: 2025 年 11 月 5 日

---

## 📋 目次

1. [概要](#1-概要)
2. [Phase 2-4 拡張計画](#2-phase-2-4-拡張計画)
3. [新カテゴリ追加時のフロー](#3-新カテゴリ追加時のフロー)
4. [マルチユーザー対応](#4-マルチユーザー対応)

---

## 1. 概要

### 1.1 拡張計画の目的

Budget Book アプリケーションの将来的な機能拡張を計画します。

**拡張の方向性**:
- **機能拡張**: 新機能の追加
- **スケーラビリティ**: データ量・ユーザー数の増加に対応
- **ユーザビリティ**: 使いやすさの向上

### 1.2 拡張フェーズ

| フェーズ | 期間 | 主な拡張内容 |
|---------|------|------------|
| **Phase 1** | 現在 | 基本機能（完了） |
| **Phase 2** | 将来 | カテゴリカスタマイズ、ルール一括インポート |
| **Phase 3** | 将来 | 分類精度レポート、機械学習による自動調整 |
| **Phase 4** | 将来 | マルチユーザー対応、データ共有機能 |

---

## 2. Phase 2-4 拡張計画

### 2.1 Phase 2: 機能拡張

#### 2.1.1 カテゴリカスタマイズ機能

**目的**: ユーザーが独自のカテゴリを追加・編集できるようにする

**実装内容**:
- カテゴリ追加機能
- カテゴリ編集機能（色・アイコン・名前）
- カテゴリ削除機能（データ整合性チェック）

**影響範囲**:
- **Categories テーブル**: ユーザーによる編集を許可
- **バリデーション**: カテゴリ削除時の整合性チェック
- **UI**: カテゴリ管理画面の追加

**実装例**:
```ruby
# カテゴリ追加
Category.create!(
  name: '医療費',
  color: '#E06C3C',
  icon: '🏥',
  description: '医療費・薬局',
  display_order: 9
)
```

#### 2.1.2 ルール一括インポート機能

**目的**: CSV ファイルから分類ルールを一括インポート

**実装内容**:
- CSV ファイルアップロード
- ルール一括登録
- 重複チェック・エラーハンドリング

**CSV フォーマット**:
```csv
category_id,keyword,priority
2,セブン,105
2,ローソン,105
6,JR,110
```

#### 2.1.3 ルール優先度の並び替え機能

**目的**: UI 上でルールの優先度をドラッグ&ドロップで変更

**実装内容**:
- 優先度の一括更新 API
- ドラッグ&ドロップ UI
- リアルタイム反映

### 2.2 Phase 3: 分析・最適化機能

#### 2.2.1 分類精度レポート

**目的**: 分類精度を分析し、改善点を提示

**実装内容**:
- 未分類取引の分析
- 分類ミスの検出
- ルール改善提案

**レポート項目**:
- 未分類取引数・割合
- カテゴリ別の分類精度
- よく分類される店舗 TOP 10
- 分類されない店舗 TOP 10

#### 2.2.2 機械学習による自動調整

**目的**: 機械学習でルールの優先度を自動調整

**実装内容**:
- 分類精度の学習
- 優先度の自動調整
- 新ルールの自動提案

**技術スタック**（検討）:
- 軽量な機械学習ライブラリ
- オフライン学習（プライバシー配慮）

### 2.3 Phase 4: マルチユーザー対応

#### 2.3.1 ユーザー認証機能

**目的**: 複数ユーザーが同じアプリケーションを使用できるようにする

**実装内容**:
- ユーザー登録・ログイン機能
- セッション管理
- パスワードリセット機能

**技術スタック**（検討）:
- Devise（Rails 認証）
- JWT（API 認証）

#### 2.3.2 データ分離

**目的**: ユーザーごとにデータを分離

**実装内容**:
- ユーザー ID を全テーブルに追加
- データ取得時にユーザー ID でフィルタリング
- データアクセス制御

**テーブル変更**:
```ruby
# マイグレーション例
add_column :transactions, :user_id, :integer
add_column :category_rules, :user_id, :integer
add_column :upload_histories, :user_id, :integer

# インデックス追加
add_index :transactions, :user_id
add_index :category_rules, :user_id
add_index :upload_histories, :user_id
```

#### 2.3.3 データ共有機能

**目的**: ユーザー間でルールを共有

**実装内容**:
- ルール共有機能
- 共有ルールのインポート
- 共有ルールの評価・フィードバック

---

## 3. 新カテゴリ追加時のフロー

### 3.1 カテゴリ追加フロー（Phase 2 以降）

```
1. ユーザーがカテゴリ管理画面で新カテゴリを追加
   ↓
2. API: POST /api/v1/categories
   → バックエンドでカテゴリ作成
   ↓
3. カテゴリマスタに追加
   → Categories テーブルに新レコード作成
   ↓
4. フロントエンドに反映
   → カテゴリ一覧に自動表示
   → グラフ・フィルタに自動反映
   ↓
5. 分類ルール作成
   → 新カテゴリ用のルールを追加
   ↓
6. CSV 自動分類に反映
   → 新しいカテゴリで分類開始
```

### 3.2 実装例

#### 3.2.1 カテゴリ追加

```ruby
# 新カテゴリ追加
category = Category.create!(
  name: '医療費',
  color: '#E06C3C',
  icon: '🏥',
  description: '医療費・薬局・健康食品',
  display_order: Category.maximum(:display_order).to_i + 1
)
```

#### 3.2.2 初期ルール追加

```ruby
# 新カテゴリ用の初期ルールを追加
initial_rules = [
  { keyword: '医院', priority: 110 },
  { keyword: '病院', priority: 110 },
  { keyword: '薬局', priority: 109 },
  { keyword: 'マツキヨ', priority: 105 }
]

initial_rules.each do |rule|
  CategoryRule.create!(
    category_id: category.id,
    keyword: rule[:keyword],
    priority: rule[:priority]
  )
end
```

### 3.3 注意点

#### 3.3.1 データ整合性

- **既存取引**: 既存の取引データは変更されない
- **表示順序**: `display_order` を適切に設定
- **色・アイコン**: 既存カテゴリと視覚的に区別できる色を選択

#### 3.3.2 フロントエンド対応

- **グラフ表示**: 新しいカテゴリの色を自動反映
- **フィルタ**: カテゴリ一覧に自動追加
- **統計**: カテゴリ別集計に自動反映

---

## 4. マルチユーザー対応

### 4.1 ユーザーテーブル設計（Phase 4）

#### 4.1.1 Users テーブル

```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email VARCHAR(255) NOT NULL UNIQUE,
  encrypted_password VARCHAR(255) NOT NULL,
  name VARCHAR(100),
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
);
```

#### 4.1.2 テーブル変更

```ruby
# マイグレーション例
class AddUserIdToTransactions < ActiveRecord::Migration[8.0]
  def change
    add_column :transactions, :user_id, :integer
    add_index :transactions, :user_id
    add_foreign_key :transactions, :users
  end
end

class AddUserIdToCategoryRules < ActiveRecord::Migration[8.0]
  def change
    add_column :category_rules, :user_id, :integer
    add_index :category_rules, :user_id
    add_foreign_key :category_rules, :users
  end
end

class AddUserIdToUploadHistories < ActiveRecord::Migration[8.0]
  def change
    add_column :upload_histories, :user_id, :integer
    add_index :upload_histories, :user_id
    add_foreign_key :upload_histories, :users
  end
end
```

### 4.2 データ分離実装

#### 4.2.1 スコープ追加

```ruby
# app/models/application_record.rb
class ApplicationRecord < ActiveRecord::Base
  # ユーザースコープ（デフォルト）
  scope :for_user, ->(user) { where(user_id: user.id) }
end

# app/models/transaction.rb
class Transaction < ApplicationRecord
  belongs_to :user
  scope :for_user, ->(user) { where(user_id: user.id) }
end
```

#### 4.2.2 コントローラー実装

```ruby
# app/controllers/api/v1/transactions_controller.rb
class Api::V1::TransactionsController < ApplicationController
  before_action :authenticate_user!
  
  def index
    transactions = current_user.transactions
    # ...
  end
end
```

### 4.3 共有機能（将来的に検討）

#### 4.3.1 ルール共有テーブル

```sql
CREATE TABLE shared_rules (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  category_rule_id INTEGER NOT NULL,
  shared_at DATETIME NOT NULL,
  download_count INTEGER DEFAULT 0,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (category_rule_id) REFERENCES category_rules(id)
);
```

#### 4.3.2 共有機能の実装

```ruby
# ルールを共有
def share_rule(rule_id)
  SharedRule.create!(
    user_id: current_user.id,
    category_rule_id: rule_id,
    shared_at: Time.current
  )
end

# 共有ルールをインポート
def import_shared_rule(shared_rule_id)
  shared_rule = SharedRule.find(shared_rule_id)
  original_rule = shared_rule.category_rule
  
  # 自分のルールとしてコピー
  CategoryRule.create!(
    user_id: current_user.id,
    category_id: original_rule.category_id,
    keyword: original_rule.keyword,
    priority: original_rule.priority
  )
  
  # ダウンロード数を更新
  shared_rule.increment!(:download_count)
end
```

---

## 5. 技術的考慮事項

### 5.1 パフォーマンス

#### 5.1.1 インデックス最適化

```ruby
# ユーザー ID での検索を高速化
add_index :transactions, [:user_id, :transaction_date]
add_index :category_rules, [:user_id, :priority]
```

#### 5.1.2 キャッシュ戦略

```ruby
# カテゴリマスタのキャッシュ
Rails.cache.fetch("categories/user_#{user.id}", expires_in: 1.hour) do
  Category.for_user(user).ordered.to_a
end
```

### 5.2 セキュリティ

#### 5.2.1 データアクセス制御

- **ユーザー認証**: すべての API リクエストで認証を必須に
- **データ分離**: ユーザー ID でフィルタリングを確実に実施
- **権限管理**: 管理者権限の実装（将来的に検討）

#### 5.2.2 バリデーション

```ruby
# ユーザー ID の整合性チェック
validates :user_id, presence: true
validate :user_id_matches_current_user

private

def user_id_matches_current_user
  if user_id != current_user.id
    errors.add(:user_id, '不正なユーザー ID です')
  end
end
```

---

## 6. まとめ

### 6.1 拡張計画の重要性

拡張計画を明確にすることで：

- **開発効率**: 将来の実装方針が明確になる
- **技術選定**: 適切な技術スタックを選択できる
- **スケーラビリティ**: データ量・ユーザー数の増加に対応できる

### 6.2 実装優先順位

1. **Phase 2**: カテゴリカスタマイズ、ルール一括インポート
2. **Phase 3**: 分類精度レポート
3. **Phase 4**: マルチユーザー対応

### 6.3 次のステップ

- [01_data_relationships.md](./01_data_relationships.md) - データ関係図
- [02_master_lifecycle.md](./02_master_lifecycle.md) - マスタライフサイクル

---

**📝 備考**: このドキュメントは、Budget Book アプリケーションの将来的な拡張計画を定義しています。実際の実装時は、要件に応じて優先順位を調整してください。



