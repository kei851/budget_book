# マッチングアルゴリズム詳細 - キーワード管理用

**バージョン**: 1.0  
**作成日**: 2025 年 10 月 31 日  
**更新日**: 2025 年 11 月 5 日

---

## 📋 目次

1. [マッチングアルゴリズム概要](#1-マッチングアルゴリズム概要)
2. [正規化処理](#2-正規化処理)
3. [優先度による複数マッチ制御](#3-優先度による複数マッチ制御)
4. [パフォーマンス考慮](#4-パフォーマンス考慮)

---

## 1. マッチングアルゴリズム概要

### 1.1 処理フロー

```
取引店名: "セブンイレブン 渋谷店"
   ↓
[正規化処理]
   → "セブンイレブン渋谷店"（空白・記号削除）
   → "せぶんいれぶんしぶやてん"（小文字化）
   ↓
[ルール照合] (優先度順)
   → Rule1: keyword="セブン" → マッチ! ✅ category_id=2 (食費)
   ↓
取引データに category_id=2 を設定
```

### 1.2 マッチング方式

| 方式 | 説明 | 例 |
|------|------|-----|
| **部分一致** | キーワードが店名に含まれるか判定 | `セブン` は `セブンイレブン` にマッチ |
| **正規化後比較** | 正規化後の文字列で比較 | 半角カタカナ・大小文字・記号を統一 |
| **優先度順** | 複数マッチ時は優先度が高いものを採用 | priority が高いルールを優先 |

### 1.3 実装メソッド

```ruby
# app/models/category_rule.rb

def self.find_category_for_store(store_name)
  return nil if store_name.blank?
  
  # 店舗名を正規化
  normalized_store_name = normalize_text(store_name)
  
  # 優先度順でキーワードマッチング
  CategoryRule.by_priority.find_each do |rule|
    normalized_keyword = normalize_text(rule.keyword)
    
    if normalized_store_name.include?(normalized_keyword)
      return rule.category
    end
  end
  
  nil
end
```

---

## 2. 正規化処理

### 2.1 正規化の目的

**正規化**は、店名とキーワードを統一された形式に変換することで、マッチング精度を向上させます。

**主な目的**:
- **半角・全角の統一**: 半角カタカナを全角カタカナに変換
- **大小文字の統一**: 大文字・小文字を統一
- **記号・空白の除去**: ハイフン・スペース・記号を削除

### 2.2 正規化処理の詳細

#### 2.2.1 正規化メソッド

```ruby
# app/models/category_rule.rb

def self.normalize_text(text)
  return '' if text.blank?
  
  # NKF を使用して正規化
  require 'nkf'
  
  # 半角カタカナを全角カタカナに変換（-Z1 オプション）
  # 小文字に統一（downcase）
  normalized = NKF.nkf('-w -Z1', text).downcase
  
  # ハイフン、スペース、記号を統一（完全一致しやすくするため）
  normalized.gsub(/[-−‐ー_\s　]/, '')
end
```

#### 2.2.2 正規化の段階

**段階 1: 半角カタカナ → 全角カタカナ**

```ruby
# NKF の -Z1 オプションを使用
NKF.nkf('-w -Z1', text)
```

**例**:
- 変換前: `ｾﾌﾞﾝ`
- 変換後: `セブン`

**段階 2: 小文字化**

```ruby
normalized.downcase
```

**例**:
- 変換前: `SEVEN`
- 変換後: `seven`

**段階 3: 記号・空白削除**

```ruby
normalized.gsub(/[-−‐ー_\s　]/, '')
```

**例**:
- 変換前: `セブン-イレブン`
- 変換後: `セブンイレブン`

### 2.3 正規化の例

#### 2.3.1 店名の正規化例

| 元の店名 | 正規化後 | 説明 |
|---------|---------|------|
| `セブンイレブン 渋谷店` | `せぶんいれぶんしぶやてん` | 空白削除、小文字化 |
| `セブン-イレブン` | `せぶんいれぶん` | ハイフン削除 |
| `SEVEN ELEVEN` | `seveneleven` | 小文字化、空白削除 |
| `ｾﾌﾞﾝｲﾚﾌﾞﾝ` | `せぶんいれぶん` | 半角カタカナ → 全角カタカナ |

#### 2.3.2 キーワードの正規化例

| 元のキーワード | 正規化後 | 説明 |
|--------------|---------|------|
| `セブン` | `せぶん` | 小文字化 |
| `SEVEN` | `seven` | 小文字化 |
| `セブン-` | `せぶん` | ハイフン削除 |

### 2.4 正規化の効果

#### 2.4.1 マッチング精度の向上

- **異なる表記の統一**: `セブン` と `ｾﾌﾞﾝ` が同じものとして扱われる
- **記号の除去**: `セブン-イレブン` と `セブンイレブン` が同じものとして扱われる
- **大小文字の統一**: `SEVEN` と `seven` が同じものとして扱われる

#### 2.4.2 マッチング例

```
店名: "セブンイレブン 渋谷店"
正規化後: "せぶんいれぶんしぶやてん"

キーワード: "セブン"
正規化後: "せぶん"

マッチング: "せぶんいれぶんしぶやてん".include?("せぶん")
→ true ✅
```

---

## 3. 優先度による複数マッチ制御

### 3.1 複数マッチの問題

**問題**: 複数のルールが同じ店名にマッチする場合、どのルールを採用するか？

**例**:
```
店名: "楽天カード"
マッチするルール:
  - 楽天 (priority: 50) → カテゴリ: 投資
  - 楽天カード (priority: 110) → カテゴリ: 投資
```

### 3.2 優先度による解決

#### 3.2.1 優先度順での照合

```ruby
# 優先度順（降順）で照合
CategoryRule.by_priority.find_each do |rule|
  if normalized_store_name.include?(normalized_keyword)
    return rule.category  # 最初にマッチしたルールを返す
  end
end
```

**効果**: 優先度が高いルールが先に照合されるため、より具体的なルールが優先される

#### 3.2.2 優先度設定の原則

| 原則 | 説明 | 例 |
|------|------|-----|
| **具体的なルールに高優先度** | より具体的なキーワードに高い優先度 | `楽天カード` (110) > `楽天` (50) |
| **汎用的なルールに低優先度** | 汎用的なキーワードに低い優先度 | `スーパー` (100) < `イオン` (105) |
| **信頼度の高いルールに高優先度** | 信頼度の高い店舗名に高い優先度 | `セブン` (105) > `コンビニ` (100) |

### 3.3 優先度設定例

#### 3.3.1 食費カテゴリの優先度設定

```ruby
# 高優先度（105）: 特定の店舗名
CategoryRule.create!(keyword: 'セブン', category_id: 2, priority: 105)
CategoryRule.create!(keyword: 'ローソン', category_id: 2, priority: 105)
CategoryRule.create!(keyword: 'ファミマ', category_id: 2, priority: 105)

# 中優先度（104）: 一般的な店舗名
CategoryRule.create!(keyword: 'マック', category_id: 2, priority: 104)
CategoryRule.create!(keyword: 'スタバ', category_id: 2, priority: 104)

# 低優先度（100）: 汎用的なキーワード
CategoryRule.create!(keyword: 'スーパー', category_id: 2, priority: 100)
CategoryRule.create!(keyword: 'コンビニ', category_id: 2, priority: 100)
```

#### 3.3.2 マッチング例

```
店名: "セブンイレブン 渋谷店"
正規化後: "せぶんいれぶんしぶやてん"

照合順序:
  1. セブン (priority: 105) → マッチ! ✅ 採用
  2. スーパー (priority: 100) → マッチするが、既に採用済み

結果: category_id = 2 (食費)
```

---

## 4. パフォーマンス考慮

### 4.1 インデックス戦略

#### 4.1.1 優先度インデックス

```sql
-- 優先度順でのソートを高速化
CREATE INDEX idx_category_rules_priority 
ON category_rules(priority DESC);
```

**効果**: `by_priority` scope でのソートが高速化

#### 4.1.2 キーワードインデックス

```sql
-- キーワード検索を高速化（将来的な拡張用）
CREATE INDEX idx_category_rules_keyword 
ON category_rules(keyword);
```

### 4.2 クエリ最適化

#### 4.2.1 効率的な照合

```ruby
# 優先度順で照合（インデックスを使用）
CategoryRule.by_priority.find_each do |rule|
  # マッチした時点で処理を終了（find_each の利点）
  if normalized_store_name.include?(normalized_keyword)
    return rule.category
  end
end
```

**最適化ポイント**:
- **優先度順**: インデックスを使用した高速ソート
- **早期終了**: マッチした時点で処理を終了
- **find_each**: 大量データでもメモリ効率的

#### 4.2.2 バッチ処理での効率化

```ruby
# 大量の取引データを処理する場合
Transaction.find_each do |transaction|
  category = CategoryRule.find_category_for_store(transaction.store_name)
  transaction.update(category_id: category&.id)
end
```

### 4.3 パフォーマンス指標

#### 4.3.1 処理時間の目安

- **1 件の照合**: 1ms 以下（通常のルール数: 50 ～ 100 件）
- **1000 件のバッチ処理**: 1 秒以下（インデックス使用時）

#### 4.3.2 改善の余地

- **キャッシュ**: よく使用されるルールをキャッシュ
- **並列処理**: 大量データの処理時に並列化
- **インデックス最適化**: 検索パターンに応じたインデックス調整

---

## 5. まとめ

### 5.1 マッチングアルゴリズムの要点

- **正規化処理**: 半角カタカナ・大小文字・記号を統一
- **優先度制御**: 複数マッチ時は優先度が高いものを採用
- **パフォーマンス**: インデックスを使用した効率的な照合

### 5.2 次のステップ

- [04_initial_rules.md](./04_initial_rules.md) - 初期ルールセット
- [05_rule_db_schema.md](./05_rule_db_schema.md) - データベーススキーマ

---

**📝 備考**: このドキュメントは、マッチングアルゴリズムの詳細を説明しています。実際の実装では、`CategoryRule.find_category_for_store` メソッドを参照してください。

