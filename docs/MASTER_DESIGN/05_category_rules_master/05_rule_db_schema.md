# 分類ルールマスタ DB スキーマ仕様書

**バージョン**: 1.0  
**作成日**: 2025 年 10 月 31 日  
**更新日**: 2025 年 11 月 5 日

---

## 📋 目次

1. [テーブル定義](#1-テーブル定義)
2. [インデックス設計](#2-インデックス設計)
3. [Seed スクリプト](#3-seed-スクリプト)
4. [マイグレーション例](#4-マイグレーション例)

---

## 1. テーブル定義

### 1.1 テーブル構造

```sql
CREATE TABLE category_rules (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  keyword VARCHAR(255) NOT NULL UNIQUE,
  category_id INTEGER NOT NULL,
  priority INTEGER NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

### 1.2 カラム詳細

| カラム名      | 型           | 制約                       | デフォルト値      | 説明                   |
| ------------- | ------------ | -------------------------- | ----------------- | ---------------------- |
| `id`          | INTEGER      | PRIMARY KEY, AUTOINCREMENT | -                 | 主キー                 |
| `keyword`     | VARCHAR(255) | NOT NULL, UNIQUE            | -                 | マッチング対象キーワード |
| `category_id` | INTEGER      | NOT NULL, FK                | -                 | 割り当てカテゴリ ID     |
| `priority`    | INTEGER      | NOT NULL                   | 0                 | 優先度（高いほど優先）   |
| `created_at`  | DATETIME     | NOT NULL                   | CURRENT_TIMESTAMP | 作成日時               |
| `updated_at`  | DATETIME     | NOT NULL                   | CURRENT_TIMESTAMP | 更新日時               |

---

## 2. インデックス設計

### 2.1 インデックス一覧

```sql
-- カテゴリ ID での検索を高速化
CREATE INDEX idx_category_rules_category_id ON category_rules(category_id);

-- キーワードでの検索を高速化
CREATE INDEX idx_category_rules_keyword ON category_rules(keyword);

-- 優先度順でのソートを高速化
CREATE INDEX idx_category_rules_priority ON category_rules(priority DESC);
```

### 2.2 インデックス詳細

#### idx_category_rules_category_id

- **対象カラム**: `category_id`
- **タイプ**: 通常インデックス
- **目的**: カテゴリ別のルール取得を高速化
- **使用クエリ例**:
  ```ruby
  CategoryRule.where(category_id: 2)
  ```

#### idx_category_rules_keyword

- **対象カラム**: `keyword`
- **タイプ**: UNIQUE インデックス
- **目的**: キーワードの重複チェック、検索を高速化
- **使用クエリ例**:
  ```ruby
  CategoryRule.find_by(keyword: 'セブン')
  ```

#### idx_category_rules_priority

- **対象カラム**: `priority`
- **タイプ**: 通常インデックス（降順）
- **目的**: 優先度順でのソートを高速化
- **使用クエリ例**:
  ```ruby
  CategoryRule.by_priority  # scope: order(priority: :desc, created_at: :desc)
  ```

---

## 3. Seed スクリプト

### 3.1 マイグレーション例

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_category_rules.rb

class CreateCategoryRules < ActiveRecord::Migration[8.0]
  def change
    create_table :category_rules do |t|
      t.string :keyword, null: false
      t.integer :category_id, null: false
      t.integer :priority, default: 0, null: false

      t.timestamps
    end

    add_index :category_rules, :category_id
    add_index :category_rules, :keyword
    add_index :category_rules, :priority
    add_foreign_key :category_rules, :categories
  end
end
```

---

## 4. マイグレーション例

### 4.1 テーブル作成

上記のマイグレーション例を参照

### 4.2 カラム追加（将来的な拡張例）

```ruby
# db/migrate/YYYYMMDDHHMMSS_add_description_to_category_rules.rb

class AddDescriptionToCategoryRules < ActiveRecord::Migration[8.0]
  def change
    add_column :category_rules, :description, :text
  end
end
```

---

**📝 備考**: このドキュメントは、分類ルールマスタのデータベース設計を定義しています。実際の実装では、Rails のマイグレーションと Model を確認してください。

