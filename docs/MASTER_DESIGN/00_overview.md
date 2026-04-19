# マスタ要件定義書 - 全体構成ガイド

**バージョン**: 1.0
**作成日**: 2025年10月31日
**更新日**: 2025年10月31日

---

## 📚 ディレクトリ構成（メニュー構成に沿った設計）

メニューの 🏷️ **キーワード管理**（CategoryRulesPage）の機能実装に必要なマスタ仕様を体系化：

```
docs/MASTER_DESIGN/
│
├─ 📋 基本情報セクション
│  ├─ 00_overview.md                        ← このファイル
│  └─ 01_master_data_architecture.md        ← マスタ全体像・ER図
│
├─ 🏷️ キーワード管理（Category Rules）セクション
│  ├─ 02_category_rules/
│  │  ├─ 01_rule_concept.md                 ← 基本概念・設計方針
│  │  ├─ 02_rule_structure.md               ← プロパティ定義
│  │  ├─ 03_matching_logic.md               ← マッチングアルゴリズム
│  │  ├─ 04_initial_rules.md                ← 初期ルールセット
│  │  └─ 05_rule_db_schema.md               ← DBスキーマ・SQL
│  │
│  └─ 03_categories/
│     ├─ 01_category_overview.md            ← 目的・仕様・一覧
│     ├─ 02_category_definitions.md         ← 8カテゴリの詳細説明
│     └─ 03_category_db_schema.md           ← DBスキーマ・SQL・初期化
│
├─ 🎨 管理画面・操作セクション
│  ├─ 04_user_interface/
│  │  ├─ 01_category_rules_page.md          ← UI要件・レイアウト
│  │  ├─ 02_rule_forms.md                   ← ルール追加・編集フォーム
│  │  └─ 03_ux_guidelines.md                ← デザインガイドライン
│  │
│  └─ 05_api_and_operations/
│     ├─ 01_rest_api_specification.md       ← API仕様（エンドポイント）
│     ├─ 02_operation_procedures.md         ← 操作手順書
│     └─ 03_bulk_operations.md              ← 一括インポート等
│
├─ 🔧 運用・拡張セクション
│  ├─ 06_maintenance/
│  │  ├─ 01_monitoring.md                   ← 監視・メンテナンス
│  │  └─ 02_troubleshooting.md              ← トラブルシューティング
│  │
│  └─ 07_extension/
│     ├─ 01_add_category.md                 ← 新カテゴリ追加
│     ├─ 02_add_rules.md                    ← ルール追加・更新
│     └─ 03_roadmap.md                      ← Phase 2-4 計画
│
└─ 📚 参考資料
   └─ 08_references.md                      ← 関連ドキュメント・用語集

```

---

## 📊 セクション一覧と役割

| # | セクション | ファイル数 | 対象 | 内容 |
|----|-----------|----------|------|------|
| 0 | **基本情報** | 2 | 全員 | マスタ全体像・関係性・ER図 |
| 1 | **キーワード管理** | 8 | 開発・PO | ルール・カテゴリ・初期データ |
| 2 | **管理画面・操作** | 6 | 開発・デザイナー・ユーザー | UI・API・操作手順 |
| 3 | **運用・拡張** | 5 | 運用・PO | 監視・トラブル・拡張・ロードマップ |
| 4 | **参考資料** | 1 | 全員 | リンク集・用語集 |
| | **合計** | **22** | | 目安: 80-100ページ |

---

## 🎯 各ファイルの詳細

### **セクション 0: 基本情報**

#### `01_master_data_architecture.md` (3-5ページ)

マスタデータシステム全体を理解するための基礎：

```
1. マスタデータとは
   - 定義と重要性
   - 分類精度・ユーザビリティへの影響

2. マスタの種類
   - カテゴリマスタ（固定）
   - 分類ルールマスタ（可変）
   - キーワードマスタ（補助）

3. ER図と関係図
   - Categories 1--N CategoryRules
   - Categories 1--N CategoryKeywords
   - Transactions N--1 Categories

4. ライフサイクル
   初期化 → 使用開始 → ユーザー編集 → 継続改善

5. 管理方針
   - カテゴリは初期値固定、ルールはユーザー可変
   - 優先度による分類ルール制御
```

---

### **セクション 1: キーワード管理（Category Rules）**

メニューの🏷️キーワード管理の中核。8ファイル (25-30ページ)

#### 1-1. `02_category_rules/01_rule_concept.md` (2-3ページ)

分類ルールの基本設計：

```
1. ルールの目的
   - CSVインポート時の自動分類
   - ユーザーが追加・編集・削除可能

2. 設計方針
   - キーワード単位での管理
   - 優先度による複数マッチ制御
   - 正規化処理による堅牢なマッチング

3. ユースケース
   - 「セブン」のキーワードで「セブンイレブン」を食費に分類
   - 優先度100 vs 110 の選別ロジック
```

#### 1-2. `02_category_rules/02_rule_structure.md` (3-4ページ)

ルールのデータ構造：

```
1. プロパティ定義
   - id (PK)
   - category_id (FK)
   - keyword (マッチング対象)
   - priority (1-200の優先度)

2. 命名規則
   - キーワード: 最大255文字
   - 重複排除: (category_id, keyword) UNIQUE

3. 優先度の意味付け
   - 100以上: 高信頼度ルール（「セブン」）
   - 50-99: 中信頼度ルール（「食堂」）
   - 1-49: 低信頼度ルール

4. バリデーション
   - キーワード必須、255文字以下
   - category_id は存在するカテゴリ参照
   - 優先度は1-200の整数
```

#### 1-3. `02_category_rules/03_matching_logic.md` (4-5ページ)

マッチングアルゴリズムの詳細：

```
1. 処理フロー
   取引「セブンイレブン 渋谷店」
   ↓ [正規化]
   「セブンイレブン渋谷店」（空白削除）
   ↓ [小文字化]
   「せぶんいれぶん しぶやてん」
   ↓ [ルール照合（優先度順）]
   Rule1: keyword="セブン" priority=105 → マッチ! category_id=1

2. 正規化ルール
   - 半角カタカナ→全角（「ｶｰﾄﾞ」→「カード」）
   - 大文字→小文字
   - 記号・空白削除

3. マッチング方式
   - キーワードが店名に部分含まれるか判定
   - 複数ルールマッチ時は最高優先度を採用

4. エッジケース例
   - 「楽天カード」: 複数ルール可能性（優先度で制御）
   - 「その他」: マッチしない場合の予備

5. パフォーマンス
   - インデックス戦略（priority, keyword）
   - バッチ処理での効率化
```

#### 1-4. `02_category_rules/04_initial_rules.md` (8-12ページ)

初期ルールセット（マスタが提供する標準値）：

```
1. 食費 (Food) - 約15キーワード
   セブン, ローソン, ファミマ (priority=105)
   マック, 吉野家, スタバ (priority=103)
   スーパー, 食堂, レストラン (priority=100)

2. 交通費 (Transport) - 約15キーワード
   JR, 私鉄, タクシー (priority=110, 105, 104)
   ガソリン, ENEOS, 昭和シェル (priority=105, 106, 106)
   ETC, 駐車場 (priority=104, 103)

3. 住宅費 (Housing) - 約5キーワード
4. 光熱・通信費 (Utilities) - 約10キーワード
5. 娯楽 (Entertainment) - 約8キーワード
6. 投資・金融 (Investment) - 約10キーワード
7. ショッピング・サービス (Shopping) - 約20キーワード
8. その他 (Other) - 該当なし

ルール選定基準
- 楽天カード利用者の一般的な店舗
- 優先度は店舗信頼度で判定
- キーワード重複排除
```

#### 1-5. `02_category_rules/05_rule_db_schema.md` (3-4ページ)

データベース設計：

```
1. テーブル定義SQL
   CREATE TABLE category_rules (
     id INTEGER PRIMARY KEY,
     category_id INTEGER NOT NULL,
     keyword VARCHAR(255) NOT NULL,
     priority INTEGER DEFAULT 50,
     created_at TIMESTAMP,
     updated_at TIMESTAMP,
     UNIQUE(category_id, keyword),
     FOREIGN KEY(category_id) REFERENCES categories(id)
   )

2. インデックス
   - name (UNIQUE)
   - category_id
   - priority (DESC)
   - keyword (検索高速化)

3. 初期化スクリプト (Seed)
4. マイグレーション例
```

#### 1-6. `03_categories/01_category_overview.md` (2-3ページ)

カテゴリマスタの概要：

```
1. 目的
   - 支出を8カテゴリに分類する基準
   - UI色分けの定義
   - 表示順序の制御

2. 8カテゴリ一覧表
   ID | 名前 | 色 | アイコン | 説明
   ---|------|-----|---------|------
   1  | 食費 | #4BC0C0 | 🍽️ | 食料品・飲食店
   2  | 交通費 | #FFCE56 | 🚗 | 交通・ガソリン
   ... (8カテゴリ全て)

3. プロパティ定義
   - id, name, ja_name, color, icon, description, display_order
   - 初期値は固定、ユーザー追加不可
```

#### 1-7. `03_categories/02_category_definitions.md` (12-15ページ)

8カテゴリの詳細説明：

```
各カテゴリについて：
├─ 説明文（1-2段落）
├─ 該当支出例（10-15例）
├─ 対象キーワード（5-10個）
├─ 除外項目（3-5個）
└─ 補足・注意点

1. 食費 (Food)
2. 交通費 (Transport)
3. 住宅費 (Housing)
4. 光熱・通信費 (Utilities)
5. 娯楽 (Entertainment)
6. 投資・金融 (Investment)
7. ショッピング・サービス (Shopping)
8. その他 (Other)
```

#### 1-8. `03_categories/03_category_db_schema.md` (2-3ページ)

```
1. テーブル定義SQL
2. インデックス
3. Seed スクリプト（8カテゴリの初期化）
4. マイグレーション例
```

---

### **セクション 2: 管理画面・操作（6ファイル, 18-20ページ）**

#### `04_user_interface/01_category_rules_page.md` (4-5ページ)

CategoryRulesPage の UI要件：

```
1. ページ全体のレイアウト
   ├─ ヘッダー（タイトル・説明）
   ├─ ルール一覧表（テーブル）
   ├─ ルール追加フォーム
   └─ フッター（説明・リンク）

2. ルール一覧表示
   テーブル構成:
   - キーワード
   - カテゴリ（色アイコン付き）
   - 優先度
   - アクション（編集・削除ボタン）

3. ソート・フィルタ
   - カテゴリ別フィルタ
   - キーワード検索
   - 優先度でソート

4. ページネーション
   - 大量ルール対応（100件以上）
```

#### `04_user_interface/02_rule_forms.md` (4-5ページ)

```
1. ルール追加フォーム
   ├─ カテゴリ選択（ドロップダウン）
   ├─ キーワード入力（テキスト）
   ├─ 優先度入力（数値）
   └─ 保存ボタン

2. ルール編集フォーム
   - 追加と同じだが、既存値をプリフィル

3. ルール削除確認
   - 確認ダイアログ

4. バリデーション UI
   - フィールドエラー表示
   - サーバーエラー表示
```

#### `04_user_interface/03_ux_guidelines.md` (3-4ページ)

```
1. デザイン方針
   - 既存UIガイドラインに準拠
   - 色使い（カテゴリ色を活用）
   - タイポグラフィ

2. アクセシビリティ
   - キーボード操作対応
   - スクリーンリーダー対応

3. レスポンシブ対応
   - デスクトップ: 3カラムレイアウト
   - タブレット: 2カラム
   - スマートフォン: 1カラム
```

#### `05_api_and_operations/01_rest_api_specification.md` (4-5ページ)

```
1. カテゴリ API
   GET /api/v1/categories

2. 分類ルール API
   GET /api/v1/category_rules
   POST /api/v1/category_rules (新規)
   PATCH /api/v1/category_rules/:id (編集)
   DELETE /api/v1/category_rules/:id (削除)

3. レスポンス例
4. エラーハンドリング
5. ページネーション仕様
```

#### `05_api_and_operations/02_operation_procedures.md` (4-5ページ)

ユーザー向けの操作手順：

```
1. ルール追加の手順書（スクリーンショット付き）
2. ルール編集の手順書
3. ルール削除の手順書
4. FAQ（よくある質問）
   - 優先度はどう選ぶ？
   - キーワード重複は？
5. トラブルシューティング
```

#### `05_api_and_operations/03_bulk_operations.md` (3-4ページ)

```
1. CSV一括インポート
   - 仕様・フォーマット
   - 実装案

2. 一括削除
   - 削除対象の選択方法
   - 確認メッセージ

3. エクスポート機能（検討中）
```

---

### **セクション 3: 運用・拡張（5ファイル, 15-18ページ）**

#### `06_maintenance/01_monitoring.md` (3-4ページ)

```
1. 定期監視項目
   - 分類精度（自動分類失敗率）
   - 未分類トランザクション数
   - ルール重複検出
   - インデックス効率

2. メトリクス
   - マッチング成功率
   - 平均処理時間
   - キャッシュ効率

3. ログ・アラート
```

#### `06_maintenance/02_troubleshooting.md` (3-4ページ)

```
1. よくあるトラブル
   - ルールがマッチしない
   - 誤分類が多い
   - パフォーマンス低下

2. 原因特定方法
3. 対応手順
```

#### `07_extension/01_add_category.md` (3-4ページ)

新カテゴリ追加ガイド：

```
1. 手順
   a. カテゴリテーブルに行追加
   b. 初期ルール追加
   c. UI・API対応
   d. テスト

2. 注意点
   - 既存トランザクション影響
   - 色選定
```

#### `07_extension/02_add_rules.md` (3-4ページ)

```
1. 単一ルール追加
2. 大量ルール追加（CSV）
3. ルール優先度調整
```

#### `07_extension/03_roadmap.md` (3-4ページ)

```
1. Phase 2 (短期)
   - ルール一括インポート完全実装
   - 分類精度レポート
   - ルール優先度の自動調整

2. Phase 3 (中期)
   - ユーザー定義カテゴリ
   - 機械学習による分類改善

3. Phase 4 (長期)
   - 他社カード対応
   - カテゴリ国際化
```

---

### **セクション 4: 参考資料**

#### `08_references.md` (2ページ)

```
1. 関連ドキュメント
   - DATABASE_SCHEMA.md
   - DATA_FLOW.md
   - COMPONENT_STRUCTURE.md
   - functional_spec.md

2. 用語集
   - マスタ、キーワード、優先度等

3. 外部参照
   - Figmaデザイン
   - Railsドキュメント
```

---

## 🔄 推奨読了順序

**初回閲覧（30分）**:
1. このファイル（00_overview.md）
2. `01_master_data_architecture.md`
3. `02_category_rules/01_rule_concept.md`

**詳細理解（1-2時間）**:
4. `03_categories/02_category_definitions.md`
5. `02_category_rules/02_rule_structure.md`
6. `02_category_rules/03_matching_logic.md`

**開発準備（2-3時間）**:
7. `02_category_rules/04_initial_rules.md`
8. `02_category_rules/05_rule_db_schema.md`
9. `03_categories/03_category_db_schema.md`
10. `05_api_and_operations/01_rest_api_specification.md`

**実装前（1-2時間）**:
11. `04_user_interface/01_category_rules_page.md`
12. `04_user_interface/02_rule_forms.md`
13. `05_api_and_operations/02_operation_procedures.md`

**運用・拡張（必要に応じて）**:
14. `06_maintenance/01_monitoring.md`
15. `07_extension/01_add_category.md`
16. `07_extension/03_roadmap.md`

---

## ✅ 次のステップ

このディレクトリ構造で、以下を確認してください：

1. **ディレクトリ構成は適切か？** ✅
   - メニュー構成に沿った分類
   - 22ファイル構成

2. **各ファイルの役割は明確か？** ✅
   - タイトル・説明で理解可能

3. **実装順序は現実的か？** ✅
   - 高優先度から順に進行

4. **このガイドで進めてよいか？**
   - ご確認ください 👇

---

**フィードバック待ちです！** 📝

