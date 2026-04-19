# カテゴリマスタ DB スキーマ仕様書

**バージョン**: 1.0  
**作成日**: 2025 年 10 月 31 日  
**更新日**: 2025 年 11 月 5 日

---

## 📋 目次

1. [テーブル定義](#1-テーブル定義)
2. [インデックス設計](#2-インデックス設計)
3. [初期化 SQL（Seed スクリプト）](#3-初期化-sqlseed-スクリプト)
4. [マイグレーション例](#4-マイグレーション例)
5. [バリデーション](#5-バリデーション)

---

## 1. テーブル定義

### 1.1 テーブル構造

```sql
CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name VARCHAR(100) NOT NULL UNIQUE,
  color VARCHAR(7) NOT NULL,
  icon VARCHAR(10),
  description TEXT,
  display_order INTEGER NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

### 1.2 カラム詳細

| カラム名        | 型           | 制約                       | デフォルト値      | 説明                     |
| --------------- | ------------ | -------------------------- | ----------------- | ------------------------ |
| `id`            | INTEGER      | PRIMARY KEY, AUTOINCREMENT | -                 | 主キー（1 ～ 7）         |
| `name`          | VARCHAR(100) | NOT NULL, UNIQUE           | -                 | カテゴリ名（日本語）     |
| `color`         | VARCHAR(7)   | NOT NULL                   | -                 | 色コード（#RRGGBB 形式） |
| `icon`          | VARCHAR(10)  | -                          | NULL              | 絵文字・アイコン         |
| `description`   | TEXT         | -                          | NULL              | カテゴリの説明文         |
| `display_order` | INTEGER      | NOT NULL                   | 0                 | UI 表示順序（昇順）      |
| `created_at`    | DATETIME     | NOT NULL                   | CURRENT_TIMESTAMP | 作成日時                 |
| `updated_at`    | DATETIME     | NOT NULL                   | CURRENT_TIMESTAMP | 更新日時                 |

### 1.3 データ型の説明

#### INTEGER (id)

- **用途**: 主キー、外部キー参照
- **範囲**: 1 ～ 7（現在のカテゴリ数）
- **特徴**: AUTOINCREMENT により自動採番

#### VARCHAR(100) (name)

- **用途**: カテゴリ名（日本語）
- **例**: "投資", "食費", "日用品費"
- **制約**: UNIQUE により重複不可

#### VARCHAR(7) (color)

- **用途**: グラフ表示用の色コード
- **形式**: `#RRGGBB` (16 進数)
- **例**: `#FF6384`, `#4BC0C0`
- **バリデーション**: 正規表現 `/\A#[0-9A-Fa-f]{6}\z/`

#### VARCHAR(10) (icon)

- **用途**: UI 表示用の絵文字・アイコン
- **例**: "💰", "🍽️", "🛒"
- **特徴**: 絵文字は UTF-8 で保存

#### TEXT (description)

- **用途**: カテゴリの詳細説明
- **例**: "証券、保険、銀行手数料"
- **特徴**: 長文に対応

#### INTEGER (display_order)

- **用途**: UI 表示順序の制御
- **値**: 1 ～ 99（小さいほど先に表示）
- **特徴**: デフォルト値 0（未設定時）

---

## 2. インデックス設計

### 2.1 インデックス一覧

```sql
-- カテゴリ名の一意性を保証（UNIQUE制約により自動生成）
CREATE UNIQUE INDEX idx_categories_name ON categories(name);

-- 表示順序でのソートを高速化
CREATE INDEX idx_categories_display_order ON categories(display_order);
```

### 2.2 インデックス詳細

#### idx_categories_name

- **対象カラム**: `name`
- **タイプ**: UNIQUE
- **目的**: カテゴリ名の重複防止、名前検索の高速化
- **使用クエリ例**:
  ```ruby
  Category.find_by(name: '食費')
  Category.find_or_create_by(name: '食費')
  ```

#### idx_categories_display_order

- **対象カラム**: `display_order`
- **タイプ**: 通常インデックス
- **目的**: 表示順序でのソートを高速化
- **使用クエリ例**:
  ```ruby
  Category.ordered  # scope: order(:display_order, :name)
  ```

### 2.3 インデックス未使用のカラム

以下のカラムにはインデックスを設定していません：

- `id`: PRIMARY KEY により自動的にインデックス化
- `color`, `icon`, `description`: 検索条件として使用されない
- `created_at`, `updated_at`: タイムスタンプ検索の必要性が低い

---

## 3. 初期化 SQL（Seed スクリプト）

### 3.1 Rails Seed スクリプト

```ruby
# db/seeds.rb または db/seeds/categories.rb

categories_data = [
  {
    name: '投資',
    color: '#FF6384',
    icon: '💰',
    description: '証券、保険、銀行手数料',
    display_order: 1
  },
  {
    name: '食費',
    color: '#4BC0C0',
    icon: '🍽️',
    description: 'スーパー、コンビニ、レストラン、カフェ',
    display_order: 2
  },
  {
    name: '日用品費',
    color: '#9966FF',
    icon: '🛒',
    description: '日用品、雑貨、消耗品',
    display_order: 3
  },
  {
    name: '娯楽費',
    color: '#36A2EB',
    icon: '🎬',
    description: '映画、ゲーム、スポーツ施設',
    display_order: 4
  },
  {
    name: '住宅費',
    color: '#FF9F40',
    icon: '🏠',
    description: '家賃、管理費、修繕費',
    display_order: 5
  },
  {
    name: '交通費',
    color: '#FFCE56',
    icon: '🚗',
    description: 'JR、私鉄、バス、タクシー、ガソリン',
    display_order: 6
  },
  {
    name: 'その他',
    color: '#C9CBCF',
    icon: '❓',
    description: '上記に該当しないもの',
    display_order: 99
  }
]

puts "カテゴリデータを投入中..."

categories_data.each do |category_attrs|
  category = Category.find_or_create_by!(name: category_attrs[:name]) do |c|
    c.color = category_attrs[:color]
    c.icon = category_attrs[:icon]
    c.description = category_attrs[:description]
    c.display_order = category_attrs[:display_order]
  end

  puts "✓ #{category.name} (#{category.color})"
end

puts "\n#{Category.count} 個のカテゴリが作成されました。"
```

### 3.2 実行方法

```bash
# Rails コンソールから実行
rails db:seed

# または、カテゴリのみ投入
rails runner "load 'db/seeds/categories.rb'"
```

### 3.3 初期データの確認

```ruby
# Rails コンソール
Category.count
# => 7

Category.ordered.pluck(:name, :display_order)
# => [["投資", 1], ["食費", 2], ["日用品費", 3], ["娯楽費", 4], ["住宅費", 5], ["交通費", 6], ["その他", 99]]
```

---

## 4. マイグレーション例

### 4.1 テーブル作成マイグレーション

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_categories.rb

class CreateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.string :color, null: false
      t.string :icon
      t.text :description
      t.integer :display_order, default: 0, null: false
      t.timestamps
    end

    add_index :categories, :name, unique: true
    add_index :categories, :display_order
  end
end
```

### 4.2 カラム追加マイグレーション（将来の拡張例）

```ruby
# db/migrate/YYYYMMDDHHMMSS_add_ja_name_to_categories.rb

class AddJaNameToCategories < ActiveRecord::Migration[8.0]
  def change
    add_column :categories, :ja_name, :string
  end
end
```

### 4.3 マイグレーション実行

```bash
# マイグレーション実行
rails db:migrate

# ロールバック（必要に応じて）
rails db:rollback
```

---

## 5. バリデーション

### 5.1 Rails Model でのバリデーション

```ruby
# app/models/category.rb

class Category < ApplicationRecord
  # 必須チェック
  validates :name, presence: true, uniqueness: true
  validates :color, presence: true, format: {
    with: /\A#[0-9A-Fa-f]{6}\z/,
    message: "must be a valid hex color code"
  }
  validates :display_order, presence: true, numericality: { only_integer: true }

  # スコープ
  scope :ordered, -> { order(:display_order, :name) }
end
```

### 5.2 バリデーション詳細

#### name のバリデーション

- **必須**: `presence: true`
- **一意性**: `uniqueness: true`
- **エラーメッセージ**: "カテゴリ名は必須です", "カテゴリ名は既に存在します"

#### color のバリデーション

- **必須**: `presence: true`
- **形式**: 正規表現 `/\A#[0-9A-Fa-f]{6}\z/`
  - `#` で始まる
  - 6 桁の 16 進数（0-9, A-F, a-f）
- **エラーメッセージ**: "色コードは #RRGGBB 形式である必要があります"

#### display_order のバリデーション

- **必須**: `presence: true`
- **数値**: `numericality: { only_integer: true }`
- **範囲**: 0 ～ 999（将来的に拡張可能）
- **エラーメッセージ**: "表示順序は整数である必要があります"

### 5.3 データベース制約

#### UNIQUE 制約

```sql
-- name カラムに UNIQUE 制約
CREATE UNIQUE INDEX idx_categories_name ON categories(name);
```

**効果**:

- データベースレベルで重複を防止
- アプリケーションレベルのバリデーションと二重チェック

#### NOT NULL 制約

```sql
-- 必須カラムに NOT NULL 制約
name VARCHAR(100) NOT NULL,
color VARCHAR(7) NOT NULL,
display_order INTEGER NOT NULL DEFAULT 0
```

**効果**:

- NULL 値の挿入を防止
- データ整合性の確保

---

## 6. リレーション

### 6.1 外部キー参照

#### Categories → Transactions (1:N)

```ruby
# app/models/category.rb
has_many :transactions, dependent: :nullify

# app/models/transaction.rb
belongs_to :category, optional: true
```

**削除時の動作**: `dependent: :nullify`

- カテゴリ削除時、関連する取引の `category_id` は NULL になる
- 取引データは保持される

#### Categories → CategoryRules (1:N)

```ruby
# app/models/category.rb
has_many :category_rules, dependent: :destroy

# app/models/category_rule.rb
belongs_to :category
```

**削除時の動作**: `dependent: :destroy`

- カテゴリ削除時、関連する分類ルールも削除される

---

## 7. パフォーマンス考慮

### 7.1 クエリ最適化

#### 表示順序でのソート

```ruby
# インデックスを使用した効率的なクエリ
Category.ordered  # scope: order(:display_order, :name)
```

**実行される SQL**:

```sql
SELECT * FROM categories
ORDER BY display_order ASC, name ASC;
```

**インデックス**: `idx_categories_display_order` が使用される

#### カテゴリ名での検索

```ruby
Category.find_by(name: '食費')
```

**実行される SQL**:

```sql
SELECT * FROM categories
WHERE name = '食費'
LIMIT 1;
```

**インデックス**: `idx_categories_name` が使用される

### 7.2 キャッシュ戦略（将来の拡張）

カテゴリマスタは変更頻度が低いため、キャッシュの対象として適しています：

```ruby
# キャッシュ例（将来の実装）
Rails.cache.fetch("categories/ordered", expires_in: 1.hour) do
  Category.ordered.to_a
end
```

---

## 8. まとめ

### 8.1 スキーマ設計の要点

- **シンプルな構造**: 必要最小限のカラムで構成
- **インデックス最適化**: 検索・ソートに必要なインデックスのみ設定
- **データ整合性**: UNIQUE 制約、NOT NULL 制約により整合性を確保
- **拡張性**: 将来的なカラム追加に対応可能

### 8.2 次のステップ

- [01_category_overview.md](./01_category_overview.md) - カテゴリマスタ概要
- [02_category_definitions.md](./02_category_definitions.md) - カテゴリ定義詳細
- [05_category_rules_master/05_rule_db_schema.md](../05_category_rules_master/05_rule_db_schema.md) - 分類ルール DB スキーマ

---

**📝 備考**: このドキュメントは、カテゴリマスタのデータベース設計を定義しています。実際の実装時は、Rails のマイグレーションと Model のバリデーションを確認してください。
