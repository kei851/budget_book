# マスタ要件定義書 - 全体構成ガイド v2.0

**バージョン**: 2.0
**作成日**: 2025 年 10 月 31 日
**更新日**: 2025 年 10 月 31 日

---

## 🎯 基本コンセプト

メニュー構成の**4 つのページ全体**をカバーするマスタ仕様書：

| ページ             | メニュー          | 機能                       | マスタ                                 |
| ------------------ | ----------------- | -------------------------- | -------------------------------------- |
| **Home**           | 🏠 トップページ   | CSV 読込・グラフ表示       | カテゴリ（分類用）                     |
| **Analytics**      | 📊 詳細分析       | 詳細検索・カテゴリ手動修正 | カテゴリ（表示用）                     |
| **Upload Manager** | 🗑️ CSV 削除管理   | CSV ファイル履歴管理       | アップロード履歴マスタ                 |
| **Category Rules** | 🏷️ キーワード管理 | ルール追加・編集・削除     | **分類ルール・カテゴリマスタ（管理）** |

---

## 📚 ディレクトリ構成（4 ページ対応設計）

```
docs/MASTER_DESIGN/
│
├─ 📋 【基本情報】セクション
│  ├─ 00_overview.md (このファイル)
│  └─ 01_master_data_architecture.md
│     ├─ マスタデータの定義・重要性
│     ├─ マスタの種類と役割
│     ├─ ER図（Categories, Transactions, Uploads, Rules）
│     └─ 全4ページで使用されるマスタ
│
├─ 🏠 【トップページ】セクション
│  └─ 02_homepage_master/
│     ├─ 01_category_overview.md
│     │  ├─ カテゴリマスタの目的（分類基準）
│     │  ├─ 8カテゴリ一覧・色・アイコン
│     │  └─ 優先度・表示順序
│     │
│     ├─ 02_category_definitions.md
│     │  └─ 8カテゴリの詳細説明
│     │     ├─ 食費, 交通費, 住宅費, 光熱・通信費
│     │     ├─ 娯楽, 投資・金融, ショッピング・サービス, その他
│     │
│     └─ 03_category_db_schema.md
│        ├─ categories テーブル定義
│        ├─ インデックス・初期化SQL
│        └─ Seed スクリプト
│
├─ 📊 【詳細分析】セクション
│  └─ 03_analytics_master/
│     ├─ 01_analytics_requirements.md
│     │  ├─ カテゴリ別フィルタ仕様
│     │  ├─ ソート・検索機能
│     │  └─ 統計表示に必要なマスタ
│     │
│     └─ 02_category_modification.md
│        ├─ カテゴリ手動修正の仕様
│        ├─ 修正時のバリデーション
│        └─ 修正ログ記録方法
│
├─ 🗑️ 【CSV削除管理】セクション
│  └─ 04_upload_history_master/
│     ├─ 01_upload_history_spec.md
│     │  ├─ 目的：CSVアップロード履歴管理
│     │  ├─ プロパティ定義（filename, upload_date等）
│     │  └─ 画面仕様（一覧・削除機能）
│     │
│     ├─ 02_upload_history_db_schema.md
│     │  ├─ upload_histories テーブル定義
│     │  ├─ transactions との関係
│     │  └─ 削除時のカスケード処理
│     │
│     └─ 03_file_management.md
│        ├─ ファイルハッシュ管理
│        ├─ 重複チェック仕様
│        └─ エンコーディング検出ロジック
│
├─ 🏷️ 【キーワード管理】セクション  ★最も重要
│  └─ 05_category_rules_master/
│     ├─ 01_rule_concept.md
│     │  ├─ 分類ルールの目的と設計方針
│     │  ├─ キーワード単位での管理
│     │  └─ 優先度による制御
│     │
│     ├─ 02_rule_structure.md
│     │  ├─ プロパティ定義（id, category_id, keyword, priority）
│     │  ├─ 命名規則・バリデーション
│     │  └─ UNIQUE制約（category_id, keyword）
│     │
│     ├─ 03_matching_logic.md
│     │  ├─ マッチングアルゴリズム詳細
│     │  ├─ 正規化処理（半角→全角、小文字化等）
│     │  ├─ 優先度による複数マッチ制御
│     │  └─ パフォーマンス考慮
│     │
│     ├─ 04_initial_rules.md
│     │  ├─ 初期ルールセット（全8カテゴリ）
│     │  ├─ 各カテゴリ 10-20キーワード
│     │  └─ ルール選定基準
│     │
│     ├─ 05_rule_db_schema.md
│     │  ├─ category_rules テーブル定義
│     │  ├─ インデックス設計
│     │  └─ Seed スクリプト
│     │
│     ├─ 06_ui_requirements.md
│     │  ├─ CategoryRulesPage UI要件
│     │  ├─ ルール一覧・追加・編集・削除フォーム
│     │  └─ レイアウト・デザイン
│     │
│     ├─ 07_api_specification.md
│     │  ├─ REST API エンドポイント
│     │  ├─ リクエスト/レスポンス仕様
│     │  └─ エラーハンドリング
│     │
│     ├─ 08_operation_guide.md
│     │  ├─ ルール追加・編集・削除手順
│     │  ├─ FAQ・トラブルシューティング
│     │  └─ 一括インポート・削除
│     │
│     └─ 09_maintenance.md
│        ├─ 定期監視項目
│        ├─ 分類精度監視
│        └─ ルール最適化ガイド
│
├─ 🔄 【統合】セクション
│  └─ 06_system_integration/
│     ├─ 01_data_relationships.md
│     │  ├─ Categories ↔ CategoryRules 関係
│     │  ├─ Transactions ↔ Categories 関係
│     │  ├─ Transactions ↔ UploadHistories 関係
│     │  └─ 全体ER図
│     │
│     ├─ 02_master_lifecycle.md
│     │  ├─ 初期化 → 使用開始 → 編集 → 改善のフロー
│     │  ├─ 4ページ間でのマスタ参照関係
│     │  └─ アップデート時の注意点
│     │
│     └─ 03_extension_roadmap.md
│        ├─ Phase 2-4 拡張計画
│        ├─ 新カテゴリ追加時のフロー
│        └─ マルチユーザー対応

```

---

## 📊 ファイル数・構成サマリー

| セクション       | ファイル数 | ページ数   | 対象読者                   |
| ---------------- | ---------- | ---------- | -------------------------- |
| 基本情報         | 2          | 3-5p       | 全員                       |
| トップページ     | 3          | 8-12p      | 開発・PO                   |
| 詳細分析         | 2          | 5-8p       | 開発・ユーザー             |
| CSV 削除管理     | 3          | 8-10p      | 開発                       |
| キーワード管理 ★ | 9          | 35-45p     | 開発・デザイナー・ユーザー |
| 統合             | 3          | 10-12p     | アーキテクト・PO           |
| **合計**         | **22**     | **70-90p** |                            |

---

## 🔍 各セクションの詳細

### **セクション 0: 基本情報** (2 ファイル, 3-5 ページ)

#### `01_master_data_architecture.md`

全 4 ページで共通に使用されるマスタデータシステム：

```
1. マスタデータとは
2. 使用マスタの種類
   - Categories（8カテゴリ）
   - CategoryRules（分類ルール）
   - UploadHistories（アップロード履歴）
3. 全体ER図（Mermaid）
4. 4ページ間の連携フロー
5. マスタ管理方針
```

---

### **セクション 1: トップページ (Home)** (3 ファイル, 8-12 ページ)

CSV 読込 → グラフ表示のページで必要なマスタ：

#### `02_homepage_master/01_category_overview.md`

- カテゴリマスタの目的（支出分類の基準）
- 8 カテゴリ一覧表（色・アイコン・優先度）
- UI 表示順序の制御

#### `02_homepage_master/02_category_definitions.md`

- 8 カテゴリの詳細説明
- 各カテゴリの該当支出例・キーワード
- グラフ表示時の色分け

#### `02_homepage_master/03_category_db_schema.md`

- `categories` テーブル定義
- イ �� デックス・初期化 SQL
- Seed スクリプト

---

### **セクション 2: 詳細分析 (Analytics)** (2 ファイル, 5-8 ページ)

カテゴリ別フィルタ・手動修正のページで必要なマスタ：

#### `03_analytics_master/01_analytics_requirements.md`

- カテゴリ別フィルタの仕様
- ソート・検索機能
- 統計表示に必要なマスタ項目

#### `03_analytics_master/02_category_modification.md`

- カテゴリ手動修正の仕様
- 修正時のバリデーション
- 修正履歴の記録方法

---

### **セクション 3: CSV 削除管理 (Upload Manager)** (3 ファイル, 8-10 ページ)

CSV アップロード履歴管理で必要なマスタ：

#### `04_upload_history_master/01_upload_history_spec.md`

- 目的：CSV アップロード履歴管理
- プロパティ定義（filename, upload_date, imported_count, file_hash 等）
- UI 画面仕様

#### `04_upload_history_master/02_upload_history_db_schema.md`

- `upload_histories` テーブル定義
- Transactions との関係（1:N）
- 削除時のカスケード処理

#### `04_upload_history_master/03_file_management.md`

- ファイルハッシュによる重複チェック
- エンコーディング検出ロジック
- BOM 処理・文字変換

---

### **セクション 4: キーワード管理 (Category Rules)** ★ (9 ファイル, 35-45 ページ)

最も重要なセクション。ルール追加・編集・削除の管理：

#### `05_category_rules_master/01_rule_concept.md` (2-3p)

分類ルールの基本設計

#### `05_category_rules_master/02_rule_structure.md` (3-4p)

プロパティ定義・バリデーション

#### `05_category_rules_master/03_matching_logic.md` (4-5p)

マッチングアルゴリズムの詳細

#### `05_category_rules_master/04_initial_rules.md` (8-12p)

初期ルールセット（全 8 カテゴリ）

#### `05_category_rules_master/05_rule_db_schema.md` (3-4p)

`category_rules` テーブル定義・インデックス

#### `05_category_rules_master/06_ui_requirements.md` (4-5p)

CategoryRulesPage の UI 要件

#### `05_category_rules_master/07_api_specification.md` (4-5p)

REST API エンドポイント仕様

#### `05_category_rules_master/08_operation_guide.md` (4-5p)

ユーザー操作マニュアル

#### `05_category_rules_master/09_maintenance.md` (3-4p)

監視・メンテナンスガイド

---

### **セクション 5: 統合** (3 ファイル, 10-12 ページ)

全 4 ページを統合した視点：

#### `06_system_integration/01_data_relationships.md`

- Categories ↔ CategoryRules 関係
- Transactions ↔ Categories 関係
- UploadHistories との関係
- 全体 ER 図

#### `06_system_integration/02_master_lifecycle.md`

- マスタ初期化 → 使用開始 → ユーザー編集 → 改善のフロー
- 4 ページ間での参照・更新の流れ

#### `06_system_integration/03_extension_roadmap.md`

- Phase 2-4 拡張計画
- 新カテゴリ追加時のフロー全体
- 長期的な進化方向

---

## 🎯 推奨読了順序

**グループ A: 基本理解（30 分）**

1. `00_overview.md` (このファイル)
2. `01_master_data_architecture.md`

**グループ B: 各ページの理解（1 時間）** 3. `02_homepage_master/01_category_overview.md` 4. `03_analytics_master/01_analytics_requirements.md` 5. `04_upload_history_master/01_upload_history_spec.md` 6. `05_category_rules_master/01_rule_concept.md`

**グループ C: 詳細仕様（2-3 時間）** 7. `02_homepage_master/02_category_definitions.md` 8. `05_category_rules_master/02_rule_structure.md` 9. `05_category_rules_master/03_matching_logic.md` 10. `05_category_rules_master/04_initial_rules.md`

**グループ D: 開発準備（2 時間）** 11. `02_homepage_master/03_category_db_schema.md` 12. `04_upload_history_master/02_upload_history_db_schema.md` 13. `05_category_rules_master/05_rule_db_schema.md` 14. `05_category_rules_master/07_api_specification.md`

**グループ E: 実装・UI（2 時間）** 15. `05_category_rules_master/06_ui_requirements.md` 16. `05_category_rules_master/08_operation_guide.md`

**グループ F: 統合・運用（1 時間）** 17. `06_system_integration/01_data_relationships.md` 18. `05_category_rules_master/09_maintenance.md`

**グループ G: 今後の計画（オプション）** 19. `06_system_integration/02_master_lifecycle.md` 20. `06_system_integration/03_extension_roadmap.md`

---

## ✅ チェックポイント

このディレクトリ構成について以下を確認：

- [ ] **4 つのページ全てをカバーしているか？**

  - 🏠 Home: トップページセクション
  - 📊 Analytics: 詳細分析セクション
  - 🗑️ Upload Manager: CSV 削除管理セクション
  - 🏷️ Category Rules: キーワード管理セクション

- [ ] **マスタの関係図が明確か？**

  - Categories（基本）
  - CategoryRules（ユーザー可変）
  - UploadHistories（追跡用）

- [ ] **実装優先度は適切か？**
  - キーワード管理（最優先）
  - トップページ（第 2 優先）
  - 詳細分析（第 3 優先）
  - CSV 削除管理（第 4 優先）

---

**この構成でいきますか？** 👇
