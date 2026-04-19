# カテゴリ手動修正仕様 - 詳細分析ページ用

**バージョン**: 1.0  
**作成日**: 2025 年 10 月 31 日  
**更新日**: 2025 年 11 月 5 日

---

## 📋 目次

1. [概要](#1-概要)
2. [カテゴリ手動修正の仕様](#2-カテゴリ手動修正の仕様)
3. [修正時のバリデーション](#3-修正時のバリデーション)
4. [修正履歴の記録方法](#4-修正履歴の記録方法)

---

## 1. 概要

### 1.1 カテゴリ手動修正の目的

**カテゴリ手動修正**は、ユーザーが自動分類された取引のカテゴリを手動で変更する機能です。

**主な用途**:
- 🔧 **分類精度の向上**: 自動分類が間違っていた場合の修正
- 📊 **データの正確性**: より正確な分析のためのデータ補正
- 🎯 **ユーザーカスタマイズ**: ユーザーの基準に合わせた分類

### 1.2 使用するマスタ

| マスタ | 用途 |
|--------|------|
| **Categories** | 修正時の選択肢（カテゴリ一覧） |
| **Transactions** | 修正対象の取引データ |

---

## 2. カテゴリ手動修正の仕様

### 2.1 UI 実装

#### 2.1.1 CategoryTag コンポーネント

取引テーブルの各取引のカテゴリは、`CategoryTag` コンポーネントで表示されます。

**機能**:
- カテゴリ名をタグ形式で表示
- クリックで編集モードに切り替え
- ドロップダウンでカテゴリを選択
- 選択後に API を呼び出して更新

**実装例**:
```vue
<CategoryTag
  :category="transaction.category"
  :categoryText="transaction.categoryText"
  @change-category="handleCategoryChange(index, $event)"
/>
```

#### 2.1.2 カテゴリ選択肢

修正時に選択できるカテゴリは、カテゴリマスタから取得します。

**推奨実装**: カテゴリマスタから動的に取得

```javascript
// カテゴリ選択肢（CategoryTag.vue）
const categoryOptions = [
  { value: '投資', text: '投資', class: 'investment' },
  { value: '食費', text: '食費', class: 'food' },
  { value: '日用品費', text: '日用品費', class: 'daily' },
  { value: '娯楽費', text: '娯楽費', class: 'entertainment' },
  { value: '住宅費', text: '住宅費', class: 'housing' },
  { value: '交通費', text: '交通費', class: 'transport' },
  { value: 'その他', text: 'その他', class: 'other' }
]
```

**将来的な改善**: API から動的に取得

```javascript
// カテゴリマスタから取得
const categories = await apiService.getCategories()
const categoryOptions = categories.map(c => ({
  value: c.id,
  text: c.name,
  class: getCategoryClass(c.name)
}))
```

### 2.2 フロントエンド処理フロー

#### 2.2.1 カテゴリ変更ハンドラ

```javascript
// AnalyticsPage.vue
const handleCategoryChange = async (index, newCategory) => {
  try {
    // 1. 変更対象の取引を取得
    const transaction = transactions.value[index]
    
    // 2. API を呼び出してバックエンドのカテゴリを更新
    const result = await apiService.updateTransaction(transaction.id, {
      category_name: newCategory.text
    })
    
    // 3. ローカルのトランザクションデータを更新
    transactions.value[index].category = getCategoryClass(newCategory.text)
    transactions.value[index].categoryText = newCategory.text
    
    // 4. チャートと統計サマリーを再読み込み
    await loadMonthData()
    
  } catch (error) {
    console.error('カテゴリ更新エラー:', error)
    alert('カテゴリの更新に失敗しました: ' + error.message)
  }
}
```

#### 2.2.2 API 呼び出し

```javascript
// api.js
async updateTransaction(id, data) {
  const response = await fetch(`${this.baseURL}/transactions/${id}`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    },
    body: JSON.stringify({
      transaction: {
        category_name: data.category_name
      }
    })
  })
  
  if (!response.ok) {
    const error = await response.json()
    throw new Error(error.error || '更新に失敗しました')
  }
  
  return await response.json()
}
```

### 2.3 バックエンド処理フロー

#### 2.3.1 コントローラー実装

```ruby
# app/controllers/api/v1/transactions_controller.rb

def update
  @transaction = Transaction.find(params[:id])
  
  # カテゴリ名からカテゴリIDを取得
  if params[:transaction][:category_name].present?
    category = Category.find_by(name: params[:transaction][:category_name])
    if category
      @transaction.category_id = category.id
      @transaction.auto_classified = false  # 手動修正フラグ
    else
      return render json: { error: 'カテゴリが見つかりません' }, 
                    status: :not_found
    end
  end
  
  if @transaction.save
    render json: transaction_json(@transaction)
  else
    render json: { errors: @transaction.errors.full_messages }, 
           status: :unprocessable_entity
  end
end
```

#### 2.3.2 データベース更新

```sql
-- 取引のカテゴリを更新
UPDATE transactions
SET category_id = :new_category_id,
    auto_classified = false,  -- 手動修正フラグ
    updated_at = datetime('now')
WHERE id = :transaction_id;
```

---

## 3. 修正時のバリデーション

### 3.1 フロントエンドバリデーション

#### 3.1.1 必須チェック

```javascript
// カテゴリ名が必須
if (!newCategory.text) {
  alert('カテゴリを選択してください')
  return
}
```

#### 3.1.2 カテゴリ存在チェック

```javascript
// 選択されたカテゴリが有効かチェック
const validCategories = ['投資', '食費', '日用品費', '娯楽費', '住宅費', '交通費', 'その他']
if (!validCategories.includes(newCategory.text)) {
  alert('無効なカテゴリです')
  return
}
```

### 3.2 バックエンドバリデーション

#### 3.2.1 カテゴリ存在チェック

```ruby
# app/controllers/api/v1/transactions_controller.rb

def update
  @transaction = Transaction.find(params[:id])
  
  if params[:transaction][:category_name].present?
    category = Category.find_by(name: params[:transaction][:category_name])
    
    unless category
      return render json: { 
        error: '指定されたカテゴリが見つかりません',
        valid_categories: Category.pluck(:name)
      }, status: :not_found
    end
    
    @transaction.category_id = category.id
  end
  
  # その他のバリデーション
  unless @transaction.save
    render json: { errors: @transaction.errors.full_messages }, 
           status: :unprocessable_entity
    return
  end
  
  render json: transaction_json(@transaction)
end
```

#### 3.2.2 Transaction モデルのバリデーション

```ruby
# app/models/transaction.rb

class Transaction < ApplicationRecord
  belongs_to :category, optional: true
  
  # カテゴリIDが存在する場合、そのカテゴリが存在することを確認
  validate :category_exists, if: -> { category_id.present? }
  
  private
  
  def category_exists
    unless Category.exists?(category_id)
      errors.add(:category_id, '指定されたカテゴリが見つかりません')
    end
  end
end
```

### 3.3 エラーハンドリング

#### 3.3.1 エラーケース

| エラーケース | エラーメッセージ | HTTP ステータス |
|-------------|----------------|----------------|
| 取引が見つからない | "取引が見つかりません" | 404 |
| カテゴリが見つからない | "指定されたカテゴリが見つかりません" | 404 |
| バリデーションエラー | バリデーションエラーメッセージ | 422 |
| サーバーエラー | "更新中にエラーが発生しました" | 500 |

#### 3.3.2 エラー表示

```javascript
// フロントエンドでのエラーハンドリング
try {
  await apiService.updateTransaction(transaction.id, {
    category_name: newCategory.text
  })
} catch (error) {
  // エラーメッセージを表示
  alert(`カテゴリの更新に失敗しました: ${error.message}`)
  
  // ログに記録
  console.error('カテゴリ更新エラー:', error)
  
  // 必要に応じて、エラー状態をUIに反映
  // 例: エラーアイコンを表示、トランザクションを元の状態に戻す
}
```

---

## 4. 修正履歴の記録方法

### 4.1 現在の実装

**現在**: 修正履歴は記録されていません。

**記録されている情報**:
- `auto_classified` フラグ: `false` に設定（手動修正を示す）
- `updated_at`: 更新日時が自動更新される

### 4.2 将来的な拡張（検討）

#### 4.2.1 修正履歴テーブル

```sql
-- 将来的に検討: 修正履歴テーブル
CREATE TABLE category_modification_histories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  transaction_id INTEGER NOT NULL,
  old_category_id INTEGER,
  new_category_id INTEGER NOT NULL,
  modified_by VARCHAR(100),  -- 将来的にユーザーID
  modified_at DATETIME NOT NULL,
  FOREIGN KEY (transaction_id) REFERENCES transactions(id),
  FOREIGN KEY (old_category_id) REFERENCES categories(id),
  FOREIGN KEY (new_category_id) REFERENCES categories(id)
);
```

#### 4.2.2 修正履歴の記録

```ruby
# 将来的な実装例
class Transaction < ApplicationRecord
  has_many :category_modification_histories
  
  def update_category!(new_category_id)
    old_category_id = self.category_id
    
    transaction do
      self.category_id = new_category_id
      self.auto_classified = false
      save!
      
      # 修正履歴を記録
      category_modification_histories.create!(
        old_category_id: old_category_id,
        new_category_id: new_category_id,
        modified_at: Time.current
      )
    end
  end
end
```

### 4.3 ログ記録

#### 4.3.1 サーバーログ

```ruby
# app/controllers/api/v1/transactions_controller.rb

def update
  @transaction = Transaction.find(params[:id])
  old_category_id = @transaction.category_id
  
  # カテゴリ更新処理...
  
  # ログに記録
  Rails.logger.info "Transaction #{@transaction.id}: Category changed from #{old_category_id} to #{@transaction.category_id}"
  
  render json: transaction_json(@transaction)
end
```

#### 4.3.2 クライアントログ

```javascript
// フロントエンドでのログ記録
const handleCategoryChange = async (index, newCategory) => {
  const transaction = transactions.value[index]
  const oldCategory = transaction.categoryText
  
  try {
    await apiService.updateTransaction(transaction.id, {
      category_name: newCategory.text
    })
    
    // ログに記録
    console.log(`Transaction ${transaction.id}: Category changed from "${oldCategory}" to "${newCategory.text}"`)
    
  } catch (error) {
    console.error('カテゴリ更新エラー:', error)
  }
}
```

---

## 5. 一括修正機能（将来的に検討）

### 5.1 一括修正の概要

同じキーワードを含む複数の取引を一度にカテゴリ修正する機能です。

**現在の実装**: `CategoryRulesPage` で一括更新機能が実装されています。

### 5.2 実装例

```ruby
# app/controllers/api/v1/category_rules_controller.rb

def bulk_update
  keyword = params[:keyword]
  new_category_id = params[:new_category_id]
  
  # キーワードを含む取引を検索
  transactions = Transaction.where(
    "LOWER(REPLACE(REPLACE(REPLACE(store_name, '-', ''), '‐', ''), ' ', '')) LIKE ?", 
    "%#{CategoryRule.normalize_text(keyword)}%"
  )
  
  # 一括更新
  updated_count = transactions.update_all(
    category_id: new_category_id,
    auto_classified: false,
    updated_at: Time.current
  )
  
  render json: {
    message: "#{updated_count}件の取引のカテゴリを更新しました",
    updated_count: updated_count
  }
end
```

---

## 6. まとめ

### 6.1 カテゴリ手動修正の重要性

カテゴリ手動修正機能は、以下の目的で重要です：

- **分類精度の向上**: 自動分類の誤りを修正
- **データの正確性**: より正確な分析のためのデータ補正
- **ユーザー満足度**: ユーザーがデータを自分で管理できる

### 6.2 実装のポイント

- **バリデーション**: カテゴリの存在チェックを必ず実施
- **エラーハンドリング**: 適切なエラーメッセージを表示
- **UI/UX**: 直感的で操作しやすい UI
- **パフォーマンス**: 更新後、必要最小限のデータのみ再読み込み

### 6.3 次のステップ

- [01_analytics_requirements.md](./01_analytics_requirements.md) - Analytics マスタ要件
- [../02_homepage_master/01_category_overview.md](../02_homepage_master/01_category_overview.md) - カテゴリマスタ概要

---

**📝 備考**: このドキュメントは、詳細分析ページ（AnalyticsPage）でのカテゴリ手動修正機能の仕様を定義しています。実際の実装では、エラーハンドリングとユーザーフィードバックを適切に実装してください。

