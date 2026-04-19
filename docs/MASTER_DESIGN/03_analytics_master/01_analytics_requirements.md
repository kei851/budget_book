# Analytics マスタ要件 - 詳細分析ページ用

**バージョン**: 1.0  
**作成日**: 2025 年 10 月 31 日  
**更新日**: 2025 年 11 月 5 日

---

## 📋 目次

1. [概要](#1-概要)
2. [カテゴリ別フィルタ仕様](#2-カテゴリ別フィルタ仕様)
3. [ソート・検索機能](#3-ソート検索機能)
4. [統計表示に必要なマスタ](#4-統計表示に必要なマスタ)

---

## 1. 概要

### 1.1 詳細分析ページの目的

**AnalyticsPage**（詳細分析ページ）は、取引データを詳細に分析・表示するためのページです。カテゴリマスタを使用して、以下の機能を提供します：

- 📊 **カテゴリ別フィルタ**: 特定のカテゴリの取引のみを表示
- 📈 **統計表示**: カテゴリ別の集計・統計情報を表示
- 🔍 **ソート機能**: 金額・日付順でソート
- ✏️ **カテゴリ手動修正**: 取引のカテゴリを手動で変更

### 1.2 使用するマスタ

| マスタ | 用途 |
|--------|------|
| **Categories** | カテゴリフィルタの選択肢、統計表示時のカテゴリ名・色 |
| **Transactions** | 分析対象の取引データ（カテゴリマスタとリレーション） |

---

## 2. カテゴリ別フィルタ仕様

### 2.1 フィルタ機能の概要

ユーザーは、カテゴリを選択して取引データをフィルタリングできます。

**UI 要素**:
- ドロップダウンリスト（`<select>`）
- 選択肢: 「全カテゴリ」+ 7 カテゴリ（投資、食費、日用品費、娯楽費、住宅費、交通費、その他）

### 2.2 フィルタ選択肢の定義

#### 2.2.1 選択肢一覧

```javascript
// フィルタ選択肢（フロントエンド実装例）
const filterOptions = [
  { value: '', label: '全カテゴリ' },      // 全カテゴリ表示
  { value: '投資', label: '投資' },
  { value: '食費', label: '食費' },
  { value: '日用品費', label: '日用品費' },
  { value: '娯楽費', label: '娯楽費' },
  { value: '住宅費', label: '住宅費' },
  { value: '交通費', label: '交通費' },
  { value: 'その他', label: 'その他' }
]
```

#### 2.2.2 カテゴリマスタからの取得

**推奨実装**: カテゴリマスタから動的に取得

```javascript
// APIからカテゴリ一覧を取得
const categories = await apiService.getCategories()

// フィルタ選択肢を生成
const filterOptions = [
  { value: '', label: '全カテゴリ' },
  ...categories.map(c => ({
    value: c.name,  // カテゴリ名（日本語）
    label: c.name
  }))
]
```

**メリット**:
- カテゴリマスタが変更されても自動的に反映
- 一貫性が保たれる

### 2.3 フィルタリングロジック

#### 2.3.1 フロントエンド実装

```javascript
// フィルタリング処理
const applyFilters = () => {
  let filtered = [...allTransactions.value]
  
  // カテゴリフィルタリング
  if (selectedCategory.value) {
    filtered = filtered.filter(t => 
      t.categoryText === selectedCategory.value
    )
  }
  
  // ソート処理
  filtered.sort((a, b) => {
    // ソートロジック...
  })
  
  transactions.value = filtered
}
```

#### 2.3.2 バックエンド実装（API）

```ruby
# app/controllers/api/v1/transactions_controller.rb

def index
  transactions = Transaction.includes(:category)
  
  # カテゴリフィルタ
  if params[:category_id].present?
    transactions = transactions.where(category_id: params[:category_id])
  end
  
  # 月フィルタ
  if params[:month].present?
    transactions = transactions.where(
      "strftime('%Y-%m', transaction_date) = ?", params[:month]
    )
  end
  
  render json: {
    transactions: transactions.map { |t| transaction_json(t) }
  }
end
```

### 2.4 フィルタ状態の管理

#### 2.4.1 状態変数

```javascript
// 選択中のカテゴリフィルタ
const selectedCategory = ref('')  // 空文字列 = 全カテゴリ
```

#### 2.4.2 フィルタ変更時の処理

```javascript
// フィルタ変更時の処理
const handleFilterChange = () => {
  applyFilters()  // フィルタリング・ソートを再実行
  updateCharts()  // チャートを更新
}
```

---

## 3. ソート・検索機能

### 3.1 ソート機能の概要

取引データを以下の順序でソートできます：

| ソート順 | 説明 | 実装例 |
|---------|------|--------|
| **金額順（高い順）** | 金額が大きい順 | `amount_desc` |
| **金額順（安い順）** | 金額が小さい順 | `amount_asc` |
| **日付順（新しい順）** | 日付が新しい順 | `date_desc` |
| **日付順（古い順）** | 日付が古い順 | `date_asc` |

### 3.2 ソート実装

#### 3.2.1 フロントエンド実装

```javascript
// ソート処理
filtered.sort((a, b) => {
  switch (sortOrder.value) {
    case 'amount_desc':  // 金額降順
      return parseFloat(b.amount.replace(/[^\d]/g, '')) - 
             parseFloat(a.amount.replace(/[^\d]/g, ''))
    case 'amount_asc':   // 金額昇順
      return parseFloat(a.amount.replace(/[^\d]/g, '')) - 
             parseFloat(b.amount.replace(/[^\d]/g, ''))
    case 'date_desc':    // 日付降順
      return new Date(b.rawDate) - new Date(a.rawDate)
    case 'date_asc':     // 日付昇順
      return new Date(a.rawDate) - new Date(b.rawDate)
    default:
      return 0
  }
})
```

#### 3.2.2 バックエンド実装（API）

```ruby
# app/controllers/api/v1/transactions_controller.rb

def index
  transactions = Transaction.includes(:category)
  
  # ソート処理
  case params[:sort]
  when 'amount_desc'
    transactions = transactions.order(amount: :desc)
  when 'amount_asc'
    transactions = transactions.order(amount: :asc)
  when 'date_desc'
    transactions = transactions.order(transaction_date: :desc)
  when 'date_asc'
    transactions = transactions.order(transaction_date: :asc)
  else
    transactions = transactions.order(transaction_date: :desc)
  end
  
  render json: {
    transactions: transactions.map { |t| transaction_json(t) }
  }
end
```

### 3.3 検索機能（将来的に検討）

**現在**: 検索機能は未実装

**将来的な拡張**:
- 店舗名による検索
- 金額範囲による検索
- 複合条件検索（カテゴリ + 店舗名 + 金額範囲）

---

## 4. 統計表示に必要なマスタ

### 4.1 統計カードの表示項目

詳細分析ページでは、以下の統計情報を表示します：

| 統計項目 | 説明 | マスタ使用 |
|---------|------|-----------|
| **総支出額** | 選択期間の合計支出 | カテゴリマスタ（集計基準） |
| **最大支出額** | 最も高い支出額 | - |
| **1 日平均支出** | 総支出 ÷ 日数 | カテゴリマスタ（集計基準） |
| **取引件数** | 取引の件数 | カテゴリマスタ（集計基準） |

### 4.2 カテゴリ別統計の計算

#### 4.2.1 カテゴリ別集計

```ruby
# バックエンド実装例
def category_statistics
  categories = Category.ordered
  stats = categories.map do |category|
    transactions = Transaction.where(
      category_id: category.id,
      transaction_date: @start_date..@end_date
    )
    
    {
      category_id: category.id,
      category_name: category.name,
      category_color: category.color,
      total_amount: transactions.sum(:amount),
      transaction_count: transactions.count
    }
  end
  
  render json: { by_category: stats }
end
```

#### 4.2.2 フロントエンドでの表示

```javascript
// カテゴリ別統計の表示
const displayCategoryStats = (stats) => {
  stats.by_category.forEach(cat => {
    console.log(`${cat.category_name}: ¥${cat.total_amount}`)
    // グラフに色（cat.category_color）を使用
  })
}
```

### 4.3 チャート表示でのマスタ使用

#### 4.3.1 円グラフ（カテゴリ別支出割合）

**使用マスタ**: `Categories`（色・名前）

```javascript
// 円グラフのデータ生成
const pieChartData = {
  labels: categories.map(c => c.name),  // カテゴリ名
  datasets: [{
    data: categoryAmounts,              // カテゴリ別金額
    backgroundColor: categories.map(c => c.color)  // カテゴリの色
  }]
}
```

#### 4.3.2 折れ線グラフ（日別推移）

**使用マスタ**: `Categories`（色・名前）

```javascript
// 折れ線グラフのデータ生成（カテゴリ別）
const lineChartData = {
  labels: dates,  // 日付
  datasets: categories.map(category => ({
    label: category.name,              // カテゴリ名
    data: dailyAmounts[category.id],    // 日別金額
    borderColor: category.color,        // カテゴリの色
    backgroundColor: category.color + '40'  // 透明度付き
  }))
}
```

### 4.4 統計表示のデータフロー

```
1. ユーザーが月を選択
   ↓
2. API: GET /api/v1/transactions?month=YYYY-MM
   → 取引データ取得（カテゴリ情報を含む）
   ↓
3. フロントエンド: カテゴリ別集計
   → カテゴリマスタの色・名前を使用
   ↓
4. UI表示
   → 統計カード
   → 円グラフ（カテゴリ別色分け）
   → 折れ線グラフ（カテゴリ別色分け）
```

---

## 5. まとめ

### 5.1 カテゴリマスタの重要性

詳細分析ページでは、カテゴリマスタが以下の役割を果たします：

- **フィルタリング**: カテゴリ別に取引を絞り込み
- **統計表示**: カテゴリ別の集計・統計を表示
- **視覚化**: グラフでの色分け・識別

### 5.2 次のステップ

- [02_category_modification.md](./02_category_modification.md) - カテゴリ手動修正の仕様
- [../02_homepage_master/01_category_overview.md](../02_homepage_master/01_category_overview.md) - カテゴリマスタ概要

---

**📝 備考**: このドキュメントは、詳細分析ページ（AnalyticsPage）でのカテゴリマスタの使用に焦点を当てています。実際の実装では、カテゴリマスタを動的に取得して使用することを推奨します。

