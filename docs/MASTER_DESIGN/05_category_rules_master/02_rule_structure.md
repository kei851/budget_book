# 分類ルール構造定義 - キーワード管理用

**バージョン**: 1.0  
**作成日**: 2025 年 10 月 31 日  
**更新日**: 2025 年 11 月 5 日

---

## 📋 目次

1. [プロパティ定義](#1-プロパティ定義)
2. [命名規則・バリデーション](#2-命名規則バリデーション)
3. [UNIQUE 制約](#3-unique-制約)
4. [データ構造例](#4-データ構造例)

---

## 1. プロパティ定義

### 1.1 プロパティ一覧

| プロパティ名 | 型 | 制約 | 説明 |
|-----------|-----|------|------|
| `id` | INTEGER | PRIMARY KEY | 主キー |
| `category_id` | INTEGER | NOT NULL, FK | 割り当てカテゴリ（外部キー） |
| `keyword` | VARCHAR(255) | NOT NULL, UNIQUE | マッチング対象のキーワード |
| `priority` | INTEGER | NOT NULL, >= 0 | 優先度（高いほど優先） |
| `created_at` | DATETIME | NOT NULL | 作成日時 |
| `updated_at` | DATETIME | NOT NULL | 更新日時 |

### 1.2 プロパティ詳細

#### id（主キー）

- **型**: INTEGER
- **制約**: PRIMARY KEY, AUTOINCREMENT
- **説明**: ルールの一意な識別子
- **用途**: データベースの主キー、API での識別

#### category_id（カテゴリ ID）

- **型**: INTEGER
- **制約**: NOT NULL, FOREIGN KEY → `categories.id`
- **説明**: マッチ時に割り当てるカテゴリ ID
- **値**: 1 ～ 7（現在のカテゴリ数）
- **用途**: カテゴリとの関連付け

#### keyword（キーワード）

- **型**: VARCHAR(255)
- **制約**: NOT NULL, UNIQUE
- **説明**: マッチング対象となるキーワード
- **例**: `セブン`, `JR`, `マック`
- **特徴**: 
  - 大文字・小文字は区別しない（内部で正規化）
  - 部分一致で判定
  - 空白・記号は削除されて比較

#### priority（優先度）

- **型**: INTEGER
- **制約**: NOT NULL, >= 0
- **説明**: 複数ルールがマッチする場合の優先度
- **範囲**: 0 ～ 999（将来的に拡張可能）
- **デフォルト**: 50（実装では指定が必要）
- **用途**: マッチング時の優先順位決定

---

## 2. 命名規則・バリデーション

### 2.1 キーワードの命名規則

#### 2.1.1 基本ルール

- **文字種**: 日本語（ひらがな・カタカナ・漢字）、英数字、記号
- **長さ**: 1 ～ 255 文字（推奨: 2 ～ 10 文字）
- **大文字・小文字**: 区別しない（内部で小文字化）
- **空白・記号**: マッチング時に削除されるため、登録時も含めないことを推奨

#### 2.1.2 推奨命名例

| 店舗名 | 推奨キーワード | 理由 |
|--------|--------------|------|
| セブンイレブン | `セブン` | 特徴的な文字列 |
| マクドナルド | `マック` | 一般的な略称 |
| JR 東日本 | `JR` | ブランド名 |
| スーパーマーケット | `スーパー` | 汎用的なキーワード |

#### 2.1.3 避けるべき命名

- **短すぎる**: `カ`（誤マッチの可能性）
- **長すぎる**: `セブンイレブン渋谷店`（具体的すぎてマッチしにくい）
- **空白・記号を含む**: `セブン イレブン`（空白は削除されるため無意味）

### 2.2 バリデーション

#### 2.2.1 Rails Model でのバリデーション

```ruby
# app/models/category_rule.rb

class CategoryRule < ApplicationRecord
  belongs_to :category
  
  # 必須チェック
  validates :keyword, presence: true, uniqueness: true
  validates :category_id, presence: true
  validates :priority, presence: true, 
            numericality: { greater_than_or_equal_to: 0 }
  
  # スコープ
  scope :by_priority, -> { order(priority: :desc, created_at: :desc) }
end
```

#### 2.2.2 バリデーション詳細

##### keyword のバリデーション

- **必須**: `presence: true`
- **一意性**: `uniqueness: true`
- **エラーメッセージ**: "キーワードは必須です", "キーワードは既に存在します"

##### category_id のバリデーション

- **必須**: `presence: true`
- **存在チェック**: 外部キー制約により、存在するカテゴリのみ許可
- **エラーメッセージ**: "カテゴリ ID は必須です", "指定されたカテゴリが見つかりません"

##### priority のバリデーション

- **必須**: `presence: true`
- **数値**: `numericality: { greater_than_or_equal_to: 0 }`
- **範囲**: 0 ～ 999（将来的に拡張可能）
- **エラーメッセージ**: "優先度は 0 以上の整数である必要があります"

### 2.3 カスタムバリデーション（将来的に検討）

#### 2.3.1 キーワード長のチェック

```ruby
# 将来的な実装例
validates :keyword, length: { minimum: 2, maximum: 50 }
```

#### 2.3.2 カテゴリ存在チェック

```ruby
# 将来的な実装例
validate :category_exists

private

def category_exists
  unless Category.exists?(category_id)
    errors.add(:category_id, '指定されたカテゴリが見つかりません')
  end
end
```

---

## 3. UNIQUE 制約

### 3.1 UNIQUE 制約の定義

#### 3.1.1 データベースレベル

```sql
-- keyword カラムに UNIQUE 制約
CREATE UNIQUE INDEX idx_category_rules_keyword 
ON category_rules(keyword);
```

**効果**: データベースレベルで同じキーワードの重複を防止

#### 3.1.2 アプリケーションレベル

```ruby
# Rails Model
validates :keyword, uniqueness: true
```

**効果**: アプリケーションレベルでも重複をチェック

### 3.2 UNIQUE 制約の意味

#### 3.2.1 現在の実装

- **keyword のみ UNIQUE**: 同じキーワードは 1 つのルールにしか登録できない
- **例**: `セブン` というキーワードは 1 つだけ存在可能

#### 3.2.2 将来的な拡張（検討）

- **複合 UNIQUE 制約**: `(category_id, keyword)` の組み合わせで UNIQUE
- **意味**: 同じキーワードでも異なるカテゴリに登録可能
- **例**: `セブン` を「食費」と「その他」の両方に登録可能

```sql
-- 将来的な拡張例
CREATE UNIQUE INDEX idx_category_rules_category_keyword 
ON category_rules(category_id, keyword);
```

### 3.3 UNIQUE 制約違反時の処理

#### 3.3.1 エラーハンドリング

```ruby
# ルール作成時
category_rule = CategoryRule.new(keyword: 'セブン', category_id: 2, priority: 105)

unless category_rule.save
  # UNIQUE 制約違反の場合
  if category_rule.errors[:keyword].include?('has already been taken')
    # エラーメッセージを表示
    render json: { 
      error: 'このキーワードは既に登録されています',
      existing_rule: CategoryRule.find_by(keyword: 'セブン')
    }, status: :unprocessable_entity
  end
end
```

---

## 4. データ構造例

### 4.1 JSON 形式

```json
{
  "id": 1,
  "category_id": 2,
  "keyword": "セブン",
  "priority": 105,
  "created_at": "2025-10-31T14:30:00.000Z",
  "updated_at": "2025-10-31T14:30:00.000Z"
}
```

### 4.2 API レスポンス形式

```json
{
  "id": 1,
  "keyword": "セブン",
  "category_id": 2,
  "category_name": "食費",
  "category_color": "#4BC0C0",
  "priority": 105,
  "matching_count": 45,
  "created_at": "2025-10-31T14:30:00.000Z",
  "updated_at": "2025-10-31T14:30:00.000Z"
}
```

**追加フィールド**:
- `category_name`: カテゴリ名（日本語）
- `category_color`: カテゴリの色コード
- `matching_count`: このキーワードにマッチする取引件数

### 4.3 データ例

#### 4.3.1 食費カテゴリのルール例

```ruby
CategoryRule.create!(
  keyword: 'セブン',
  category_id: 2,  # 食費
  priority: 105
)

CategoryRule.create!(
  keyword: 'ローソン',
  category_id: 2,  # 食費
  priority: 105
)

CategoryRule.create!(
  keyword: 'マック',
  category_id: 2,  # 食費
  priority: 104
)
```

#### 4.3.2 交通費カテゴリのルール例

```ruby
CategoryRule.create!(
  keyword: 'JR',
  category_id: 6,  # 交通費
  priority: 110
)

CategoryRule.create!(
  keyword: 'ガソリン',
  category_id: 6,  # 交通費
  priority: 105
)
```

---

## 5. まとめ

### 5.1 プロパティ定義の要点

- **シンプルな構造**: 必要最小限のプロパティで構成
- **UNIQUE 制約**: キーワードの重複を防止
- **バリデーション**: データ整合性を確保
- **拡張性**: 将来的な拡張に対応可能

### 5.2 次のステップ

- [03_matching_logic.md](./03_matching_logic.md) - マッチングアルゴリズム詳細
- [04_initial_rules.md](./04_initial_rules.md) - 初期ルールセット
- [05_rule_db_schema.md](./05_rule_db_schema.md) - データベーススキーマ

---

**📝 備考**: このドキュメントは、分類ルールのプロパティ定義とバリデーションを説明しています。実際の実装では、Rails Model のバリデーションを確認してください。

