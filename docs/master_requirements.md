# マスタ要件定義書 - Budget Book

**バージョン**: 1.0
**作成日**: 2025年10月31日
**更新日**: 2025年10月31日

---

## 📋 概要

本ドキュメントは、Budget Book アプリケーションで使用される各種マスタデータ（カテゴリ、分類ルール等）の要件を定義します。これらのマスタは、取引データの自動分類、カテゴリ管理、ユーザーカスタマイズの基盤となります。

---

## 1. マスタデータ全体像

### 1.1 マスタの種類と役割

| マスタ名 | 目的 | 管理方法 | 利用範囲 |
|---------|------|---------|---------|
| **カテゴリマスタ** | 7つの支出カテゴリを定義 | 初期値で固定 | CSV分類・表示・分析 |
| **分類ルールマスタ** | 店名→カテゴリのマッピングルール | ユーザーが作成・編集・削除可能 | CSV自動分類 |
| **キーワードマスタ** | 分類ルールに含まれるキーワード | ルール作成時に定義 | 店名マッチング |

### 1.2 マスタデータのライフサイクル

```
初期化（DBマイグレーション）
    ↓
ユーザー操作（追加・編集・削除）
    ↓
CSV取引分類で利用
    ↓
分類精度向上・ルール調整
```

---

## 2. カテゴリマスタ仕様

### 2.1 目的と設計方針

**目的**:
- 支出を7つのカテゴリに分類する基準を提供
- グラフ表示時のカテゴリ別色分けの定義
- UI表示の順序制御

**設計方針**:
- 初期値は固定で、ユーザーは追加・削除不可（編集は検討）
- カテゴリ名・色・アイコンは視覚的に識別しやすい設計
- 優先度（display_order）により表示順序を制御

### 2.2 カテゴリ一覧定義

#### 2.2.1 基本情報

| ID | カテゴリ名 | 和名 | 色コード | アイコン | 説明 | 優先度 |
|----|---------|------|--------|--------|------|--------|
| 1 | Food | 食費 | #4BC0C0 | 🍽️ | 食料品・飲食店・カフェ | 1 |
| 2 | Transport | 交通費 | #FFCE56 | 🚗 | 交通運賃・ガソリン・駐車料金 | 2 |
| 3 | Housing | 住宅費 | #FF6B6B | 🏠 | 家賃・管理費・修繕費 | 3 |
| 4 | Utilities | 光熱・通信費 | #FF9F40 | ⚡ | 電気・ガス・水道・通信料 | 4 |
| 5 | Entertainment | 娯楽 | #36A2EB | 🎬 | 映画・ゲーム・スポーツ施設 | 5 |
| 6 | Investment | 投資・金融 | #FF6384 | 💰 | 証券・保険・手数料 | 6 |
| 7 | Shopping | ショッピング・サービス | #9966FF | 👜 | 衣料品・家電・美容・医療・教育 | 7 |
| 8 | Other | その他 | #C9CBCF | ❓ | 上記に該当しないもの | 8 |

#### 2.2.2 カテゴリ詳細説明

##### 1. 食費 (Food)

**該当する支出例**:
- スーパーマーケット（セブンイレブン、ローソン、ファミリーマート等）
- コンビニエンスストア
- レストラン・和食店・洋食店
- ファーストフード（マクドナルド、ケンタッキー等）
- カフェ（スターバックス等）
- 飲料店（タピオカドリンク等）
- デリバリー・テイクアウト

**対象キーワード例** (後述のルールマスタに登録):
- スーパー、セブン、ローソン、ファミマ
- マック、ケンタ、吉野家
- スタバ、カフェ
- 食堂、レストラン

**除外すべき支出** (他カテゴリに分類):
- 食材の購入時の配送料（交通費ではなく食費に含める）
- 飲料・タバコ（食費に含める）

---

##### 2. 交通費 (Transport)

**該当する支出例**:
- 電車運賃（JR、私鉄等）
- バス運賃
- タクシー乗車料金
- ガソリンスタンドでの給油
- 駐車場料金・駐輪場料金
- 高速道路料金・ETC
- 飛行機チケット
- 新幹線チケット

**対象キーワード例**:
- JR、私鉄、電車、バス、タクシー
- ガソリン、ENEOS、昭和シェル、コスモ
- 駐車場、ETC
- 航空券、新幹線

---

##### 3. 住宅費 (Housing)

**該当する支出例**:
- 家賃
- 住宅ローン返済
- 管理費・共益費
- 修繕費・リフォーム
- 不動産関連手数料

**対象キーワード例**:
- 大家、管理会社、家賃
- 住宅ローン

---

##### 4. 光熱・通信費 (Utilities)

**該当する支出例**:
- 電力会社への支払い（東京電力等）
- ガス会社への支払い
- 水道料金
- 携帯電話料金（NTTドコモ、au、ソフトバンク等）
- インターネット（プロバイダ、光回線等）

**対象キーワード例**:
- 東京電力、関西電力
- ガス会社、東京ガス
- 水道局
- ドコモ、au、ソフトバンク
- インターネット、プロバイダ

---

##### 5. 娯楽 (Entertainment)

**該当する支出例**:
- 映画館チケット
- ゲーム・ソフト購入
- スポーツ施設利用料（ジム、ヨガ教室等）
- コンサート・イベントチケット
- 書籍・雑誌購入
- 趣味用品（カメラ機材等）

**対象キーワード例**:
- 映画、シネマ
- ゲーム、Steam
- ジム、スポーツ
- コンサート、チケット

---

##### 6. 投資・金融 (Investment)

**該当する支出例**:
- 証券会社での取引・手数料
- 保険料（生命保険、損害保険等）
- 銀行手数料
- 投資信託・株式購入
- 仮想通貨取引

**対象キーワード例**:
- 証券、SBI、楽天証券
- 保険、損保ジャパン
- 銀行手数料
- クレジットカード年会費

---

##### 7. ショッピング・サービス (Shopping)

**該当する支出例**:
- 衣料品店（ユニクロ、GU、ZARA等）
- 靴・バッグ販売店
- 家電量販店（ビックカメラ、ヨドバシ等）
- インテリア・雑貨店（IKEA、無印良品等）
- ドラッグストア（マツキヨ、サンドラッグ等）
- 美容院・理髪店
- 医療機関（病院、歯科等）
- 教育サービス（塾、オンライン講座等）
- クリーニング店
- 家事代行サービス

**対象キーワード例**:
- ユニクロ、GU、ZARA、H&M
- ビックカメラ、ヨドバシ、ソフマップ
- IKEA、無印良品、ニトリ
- マツキヨ、サンドラッグ
- 美容院、理髪
- 医院、歯科
- 塾、オンライン講座

---

##### 8. その他 (Other)

**該当する支出例**:
- 分類不明な支出
- 複合カテゴリに該当する支出
- 初期状態で未分類のもの

**注**: このカテゴリは自動分類が失敗した場合の予備となります

---

### 2.3 カテゴリマスタのプロパティ詳細

#### 2.3.1 id (主キー)

- **型**: INTEGER
- **制約**: PRIMARY KEY, NOT NULL, AUTO_INCREMENT
- **説明**: カテゴリの一意な識別子（1～8）

#### 2.3.2 name (名前・一意制約)

- **型**: VARCHAR(100)
- **制約**: UNIQUE, NOT NULL
- **説明**: カテゴリの名前（英語）
- **例**: "Food", "Transport"
- **使用箇所**: DB保存、API応答、ロジック処理

#### 2.3.3 ja_name (日本語名)

- **型**: VARCHAR(100)
- **説明**: カテゴリの日本語表記
- **例**: "食費", "交通費"
- **使用箇所**: UI表示、レポート

#### 2.3.4 color (カラーコード)

- **型**: VARCHAR(7)
- **制約**: NOT NULL
- **形式**: "#RRGGBB" (16進数色コード)
- **説明**: グラフ表示時の色
- **例**: "#4BC0C0"
- **使用箇所**: Chart.js グラフの色指定

#### 2.3.5 icon (アイコン)

- **型**: VARCHAR(10)
- **説明**: UI表示用の絵文字またはアイコン
- **例**: "🍽️", "🚗", "🏠"
- **使用箇所**: UI表示、テーブル表示

#### 2.3.6 description (説明)

- **型**: TEXT
- **説明**: カテゴリの詳細説明
- **例**: "食料品・飲食店・カフェ"
- **使用箇所**: UI上のヘルプテキスト

#### 2.3.7 display_order (表示順序)

- **型**: INTEGER
- **制約**: NOT NULL
- **説明**: UI表示時の優先度（昇順で表示）
- **値**: 1～8
- **使用箇所**: UI表示、グラフの凡例順序

#### 2.3.8 created_at, updated_at (タイムスタンプ)

- **型**: TIMESTAMP
- **説明**: 作成日時・更新日時
- **管理**: Rails自動管理

---

### 2.4 カテゴリマスタのDBスキーマ

```sql
CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100) UNIQUE NOT NULL,
  ja_name VARCHAR(100),
  color VARCHAR(7) NOT NULL,
  icon VARCHAR(10),
  description TEXT,
  display_order INTEGER NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- インデックス
CREATE UNIQUE INDEX idx_categories_name ON categories(name);
CREATE INDEX idx_categories_display_order ON categories(display_order);
```

---

### 2.5 カテゴリマスタ初期化スクリプト

```ruby
# db/seeds.rb または db/seeds/categories.rb

categories_data = [
  { name: 'Food', ja_name: '食費', color: '#4BC0C0', icon: '🍽️', description: '食料品・飲食店・カフェ', display_order: 1 },
  { name: 'Transport', ja_name: '交通費', color: '#FFCE56', icon: '🚗', description: '交通運賃・ガソリン・駐車料金', display_order: 2 },
  { name: 'Housing', ja_name: '住宅費', color: '#FF6B6B', icon: '🏠', description: '家賃・管理費・修繕費', display_order: 3 },
  { name: 'Utilities', ja_name: '光熱・通信費', color: '#FF9F40', icon: '⚡', description: '電気・ガス・水道・通信料', display_order: 4 },
  { name: 'Entertainment', ja_name: '娯楽', color: '#36A2EB', icon: '🎬', description: '映画・ゲーム・スポーツ施設', display_order: 5 },
  { name: 'Investment', ja_name: '投資・金融', color: '#FF6384', icon: '💰', description: '証券・保険・手数料', display_order: 6 },
  { name: 'Shopping', ja_name: 'ショッピング・サービス', color: '#9966FF', icon: '👜', description: '衣料品・家電・美容・医療・教育', display_order: 7 },
  { name: 'Other', ja_name: 'その他', color: '#C9CBCF', icon: '❓', description: '上記に該当しないもの', display_order: 8 }
]

categories_data.each do |cat|
  Category.find_or_create_by(name: cat[:name]) do |c|
    c.ja_name = cat[:ja_name]
    c.color = cat[:color]
    c.icon = cat[:icon]
    c.description = cat[:description]
    c.display_order = cat[:display_order]
  end
end
```

---

## 3. 分類ルールマスタ仕様

### 3.1 目的と設計方針

**目的**:
- CSVインポート時に店名からカテゴリを自動判定するためのルール集
- ユーザーが追加・編集・削除可能なマスタ
- 分類精度を継続的に向上させるためのベース

**設計方針**:
- キーワード単位での優先度制御（priority フィールド）
- 複数のキーワードで同じカテゴリを指す場合に対応
- ユーザーが新しいルールを追加することで、分類精度を改善可能

### 3.2 分類ルール定義

#### 3.2.1 ルールの基本構造

```javascript
{
  id: 1,
  category_id: 1,          // Food
  keyword: "セブン",        // マッチング対象
  priority: 100,            // 優先度（高いほど優先）
  created_at: "...",
  updated_at: "..."
}
```

#### 3.2.2 マッチングロジック

**処理フロー**:

```
取引店名: "セブンイレブン 渋谷店"
        ↓
[正規化処理]
        → "セブンイレブン渋谷店"（空白削除）
        → "せぶんいれぶん しぶやてん"（小文字化）
        ↓
[ルール照合] (優先度 DESC で順序処理)
        Rule1: keyword="セブン" → マッチ! ✅ category_id=1 (Food)
```

**マッチング方式**:
- キーワード方式: 正規化後の店名に含まれるキーワード
- 部分一致: "セブン" はセブンイレブンにマッチ
- 優先度順: 複数ルールがマッチする場合は priority が高いものを採用

#### 3.2.3 初期ルールセット

以下は、初期設定として提供されるルール例です（実装時に拡張）:

**食費 (category_id=1)** - 優先度 100～110

| ID | キーワード | 優先度 | 説明 |
|----|----------|--------|------|
| 1 | セブン | 105 | セブンイレブン |
| 2 | ローソン | 105 | ローソン |
| 3 | ファミマ | 105 | ファミリーマート |
| 4 | マック | 104 | マクドナルド |
| 5 | 吉野家 | 103 | 吉野家 |
| 6 | スタバ | 103 | スターバックス |
| 7 | スーパー | 100 | 汎用スーパー |
| 8 | 食堂 | 100 | 汎用食堂 |
| 9 | レストラン | 100 | 汎用レストラン |

**交通費 (category_id=2)** - 優先度 100～110

| ID | キーワード | 優先度 | 説明 |
|----|----------|--------|------|
| 20 | JR | 110 | JR運賃 |
| 21 | 私鉄 | 105 | 私鉄運賃 |
| 22 | タクシー | 104 | タクシー乗車 |
| 23 | ガソリン | 105 | ガソリンスタンド |
| 24 | ENEOS | 106 | ENEOS |
| 25 | 昭和シェル | 106 | 昭和シェル |
| 26 | コスモ | 106 | コスモ石油 |
| 27 | ETC | 104 | 高速料金 |
| 28 | 駐車場 | 103 | 駐車料金 |

**投資・金融 (category_id=6)** - 優先度 100～110

| ID | キーワード | 優先度 | 説明 |
|----|----------|--------|------|
| 50 | 楽天証券 | 110 | 楽天証券 |
| 51 | SBI証券 | 110 | SBI証券 |
| 52 | 保険 | 105 | 保険各社 |
| 53 | クレジットカード | 104 | カード年会費 |
| 54 | 銀行 | 100 | 銀行手数料 |

（その他のカテゴリも同様に定義）

### 3.3 分類ルールマスタのプロパティ詳細

#### 3.3.1 id (主キー)

- **型**: INTEGER
- **制約**: PRIMARY KEY, NOT NULL, AUTO_INCREMENT

#### 3.3.2 category_id (外部キー)

- **型**: INTEGER
- **制約**: FOREIGN KEY → categories(id), NOT NULL
- **説明**: マッチ時に割り当てるカテゴリID

#### 3.3.3 keyword (キーワード)

- **型**: VARCHAR(255)
- **制約**: NOT NULL
- **説明**: マッチング対象となるキーワード
- **例**: "セブン", "JR", "保険"
- **仕様**:
  - 大文字・小文字は区別しない（内部で小文字化）
  - 部分一致で判定（"セブン" は "セブンイレブン" にマッチ）
  - 空白は削除されて比較（"セブン イレブン" = "セブンイレブン"）

#### 3.3.4 priority (優先度)

- **型**: INTEGER
- **制約**: NOT NULL, DEFAULT 50
- **値**: 1～200
  - 100以上: 信頼度が高いルール
  - 50～99: 中程度の信頼度
  - 1～49: 信頼度が低いルール
- **説明**: 複数ルールがマッチする場合、優先度が高いものを採用
- **使用例**:
  - "楽天" (priority=50) は "楽天カード", "楽天トラベル" にマッチ
  - "楽天カード" (priority=110) の方が優先される

#### 3.3.5 created_at, updated_at (タイムスタンプ)

- **型**: TIMESTAMP

---

### 3.4 分類ルールマスタのDBスキーマ

```sql
CREATE TABLE category_rules (
  id INTEGER PRIMARY KEY AUTO_INCREMENT,
  category_id INTEGER NOT NULL,
  keyword VARCHAR(255) NOT NULL,
  priority INTEGER NOT NULL DEFAULT 50,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (category_id) REFERENCES categories(id),
  UNIQUE KEY unique_category_keyword (category_id, keyword)
);

-- インデックス
CREATE INDEX idx_category_rules_category_id ON category_rules(category_id);
CREATE INDEX idx_category_rules_priority ON category_rules(priority DESC);
CREATE INDEX idx_category_rules_keyword ON category_rules(keyword);
```

---

### 3.5 分類ルール管理の運用

#### 3.5.1 ルール追加フロー

**UI操作**:

```
CategoryRulesPage
  ├─ "新しいルールを追加" ボタン
  │   ↓
  ├─ Form表示
  │   ├─ category: ドロップダウン
  │   ├─ keyword: テキスト入力
  │   └─ priority: 数値入力（デフォルト: 50）
  │   ↓
  └─ "保存" ボタン
      ↓
  API: POST /api/v1/category_rules
      ↓
  success/error メッセージ表示
```

#### 3.5.2 ルール一括インポート

**用途**: 大量のルールを一括でインポート（CSV形式）

**CSVフォーマット**:

```csv
category_id,keyword,priority
1,セブン,105
1,ローソン,105
1,ファミマ,105
2,JR,110
2,ガソリン,105
...
```

**実装方法**:

```ruby
# API Endpoint (検討中)
POST /api/v1/category_rules/import

# CSV ファイルアップロード → 一括処理
```

---

## 4. キーワードマスタ（補助）

### 4.1 概要

分類ルールに含まれるキーワードを一元管理するための補助マスタ。分類ルールマスタと密接に関連します。

### 4.2 スキーマ

```sql
CREATE TABLE category_keywords (
  id INTEGER PRIMARY KEY AUTO_INCREMENT,
  category_id INTEGER NOT NULL,
  keyword VARCHAR(255) NOT NULL,
  priority INTEGER NOT NULL DEFAULT 50,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (category_id) REFERENCES categories(id),
  INDEX idx_category_id (category_id),
  INDEX idx_keyword (keyword)
);
```

**注**: 分類ルールマスタとの関係を整理する必要があります。

---

## 5. マスタの拡張性・保守性

### 5.1 新しいカテゴリの追加方法

#### ケース: 新カテゴリ「医療・健康」を追加する場合

1. **カテゴリマスタに行を追加**

```sql
INSERT INTO categories (
  name, ja_name, color, icon, description, display_order
) VALUES (
  'Healthcare',
  '医療・健康',
  '#E06C3C',
  '🏥',
  '医療費・薬局・健康食品',
  9
);
```

2. **分類ルールマスタにルールを追加**

```sql
INSERT INTO category_rules (category_id, keyword, priority) VALUES
((SELECT id FROM categories WHERE name='Healthcare'), '医院', 110),
((SELECT id FROM categories WHERE name='Healthcare'), '病院', 110),
((SELECT id FROM categories WHERE name='Healthcare'), '薬局', 109),
((SELECT id FROM categories WHERE name='Healthcare'), 'マツキヨ', 105),
...
```

3. **フロントエンド対応**

- UI の色設定、表示順序を自動更新（マスタから読み込み）
- CategoryRulesPage に新カテゴリが自動表示される

---

### 5.2 ルールの更新・削除方法

#### ルール削除 (優先度が低い古いルール)

```sql
DELETE FROM category_rules
WHERE keyword='古いキーワード' AND category_id=1;
```

#### ルール優先度の変更

```sql
UPDATE category_rules
SET priority=150
WHERE keyword='セブン' AND category_id=1;
```

---

### 5.3 メンテナンス・監視ポイント

| 項目 | 内容 |
|------|------|
| **分類精度監視** | 自動分類失敗率を定期的に確認 |
| **未分類トランザクション** | category_id = NULL のレコード数を監視 |
| **ルール重複** | 同じキーワード・カテゴリ組み合わせの検出 |
| **外部キー整合性** | category_id が categories に存在するか確認 |

---

## 6. マスタ管理画面 (CategoryRulesPage)

### 6.1 機能一覧

- ✅ ルール一覧表示（キーワード、カテゴリ、優先度）
- ✅ ルール追加フォーム
- ✅ ルール編集機能
- ✅ ルール削除機能
- 🔄 一括インポート機能（CSV）
- 🔄 ルール優先度の並び替え
- 🔄 分類精度レポート

### 6.2 UI要件

**表示項目**:

| カラム | 型 | 説明 |
|-------|-----|------|
| キーワード | text | マッチング対象 |
| カテゴリ | select | 割り当てカテゴリ |
| 優先度 | number | マッチング優先度 |
| アクション | button | 編集・削除ボタン |

---

## 7. API仕様

### 7.1 カテゴリ取得

```
GET /api/v1/categories

レスポンス:
{
  "categories": [
    {
      "id": 1,
      "name": "Food",
      "ja_name": "食費",
      "color": "#4BC0C0",
      "icon": "🍽️",
      "display_order": 1
    },
    ...
  ]
}
```

### 7.2 分類ルール取得

```
GET /api/v1/category_rules

レスポンス:
{
  "rules": [
    {
      "id": 1,
      "category_id": 1,
      "keyword": "セブン",
      "priority": 105,
      "category_name": "Food",
      "category_ja_name": "食費"
    },
    ...
  ]
}
```

### 7.3 分類ルール作成

```
POST /api/v1/category_rules

リクエスト:
{
  "category_rule": {
    "category_id": 1,
    "keyword": "新しいキーワード",
    "priority": 80
  }
}

レスポンス:
{
  "id": 999,
  "category_id": 1,
  "keyword": "新しいキーワード",
  "priority": 80
}
```

### 7.4 分類ルール削除

```
DELETE /api/v1/category_rules/:id

レスポンス:
{
  "message": "ルールを削除しました"
}
```

---

## 8. バリデーション・エラー処理

### 8.1 カテゴリマスタ

| 項目 | バリデーション | エラーメッセージ |
|------|-----------------|-----------------|
| name | 英語のみ、一意 | "カテゴリ名は一意でなければなりません" |
| color | #RRGGBB 形式 | "色コードは #RRGGBB 形式である必要があります" |
| display_order | 1～100の整数 | "優先度は1～100の整数である必要があります" |

### 8.2 分類ルールマスタ

| 項目 | バリデーション | エラーメッセージ |
|------|-----------------|-----------------|
| category_id | 存在する category を参照 | "指定されたカテゴリが見つかりません" |
| keyword | 空でない、1～255文字 | "キーワードは1～255文字である必要があります" |
| keyword | (category_id, keyword) 一意 | "このカテゴリとキーワードの組み合わせは既に存在します" |
| priority | 1～200の整数 | "優先度は1～200の整数である必要があります" |

---

## 9. マスタ初期化・マイグレーション

### 9.1 初期化スクリプト

```bash
# マイグレーション実行
rails db:migrate

# Seed データ投入
rails db:seed
```

### 9.2 マイグレーション時の考慮事項

- **既存データの保護**: ユーザーが追加したルールは保持
- **インデックス**: 検索・ソート性能のため、適切にインデックス設定
- **外部キー制約**: データ整合性を確保

---

## 10. 今後の拡張予定

### 10.1 Phase 2

- [ ] ルール一括インポート機能
- [ ] 分類精度レポート
- [ ] ルール優先度の自動調整（機械学習）

### 10.2 Phase 3

- [ ] カテゴリのカスタマイズ機能（ユーザー定義カテゴリ）
- [ ] ルール複製・テンプレート機能
- [ ] マルチユーザー対応時のルール共有

---

## 11. 関連ドキュメント参照

- [DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md) - 詳細なDBスキーマ
- [functional_spec.md](./functional_spec.md) - 機能仕様
- [DATA_FLOW.md](./DATA_FLOW.md) - データフロー（カテゴリ自動分類）

---

## 12. 承認・変更履歴

### 12.1 作成

- **作成者**: Claude
- **作成日**: 2025年10月31日
- **バージョン**: 1.0

### 12.2 変更予定

| バージョン | 変更内容 | 予定日 |
|-----------|---------|--------|
| 1.1 | 初期ルールセット完成度向上 | 2025年11月 |
| 1.2 | ルール一括インポート仕様追加 | 2025年11月 |

