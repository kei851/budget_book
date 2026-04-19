# マスタ要件定義書 - メインインデックス

**バージョン**: 2.1
**作成日**: 2025年10月31日
**更新日**: 2025年10月31日

---

## 🎯 マスタ仕様書の全体構成

メニューの **4つのページ** に対応した、ディレクトリ分割型の構成：

```
docs/MASTER_DESIGN/
│
├─ 00_MASTER_INDEX.md             ← このファイル。全体インデックス
│
├─ 01_MASTER_ARCHITECTURE.md       ← マスタデータ全体像・ER図
│
├─ 🏠_HOME/                         ← トップページ用マスタ
│  ├─ README.md
│  ├─ 01_category_overview.md      ← カテゴリ一覧・仕様
│  ├─ 02_category_definitions.md   ← 8カテゴリ詳細説明
│  └─ 03_category_db_schema.md     ← DBスキーマ・SQL
│
├─ 📊_ANALYTICS/                    ← 詳細分析ページ用マスタ
│  ├─ README.md
│  ├─ 01_analytics_requirements.md ← フィルタ・検索仕様
│  └─ 02_category_modification.md  ← カテゴリ修正仕様
│
├─ 🗑️_UPLOAD_MANAGER/              ← CSV削除管理用マスタ
│  ├─ README.md
│  ├─ 01_upload_history_spec.md    ← アップロード履歴仕様
│  ├─ 02_upload_history_db_schema.md ← DBスキーマ
│  └─ 03_file_management.md        ← ファイル管理ロジック
│
├─ 🏷️_CATEGORY_RULES/              ← キーワード管理用マスタ ★最重要
│  ├─ README.md
│  ├─ 01_rule_concept.md           ← ルール基本概念
│  ├─ 02_rule_structure.md         ← ルール構造・プロパティ
│  ├─ 03_matching_logic.md         ← マッチングアルゴリズム
│  ├─ 04_initial_rules.md          ← 初期ルールセット
│  ├─ 05_rule_db_schema.md         ← DBスキーマ・SQL
│  ├─ 06_ui_requirements.md        ← UI要件・レイアウト
│  ├─ 07_api_specification.md      ← REST API 仕様
│  ├─ 08_operation_guide.md        ← 操作マニュアル
│  └─ 09_maintenance.md            ← 監視・メンテナンス
│
└─ 📚_INTEGRATION/                  ← 統合・関連情報
   ├─ README.md
   ├─ 01_data_relationships.md     ← マスタ関係図・ER図
   ├─ 02_master_lifecycle.md       ← ライフサイクル
   └─ 03_extension_roadmap.md      ← 拡張計画（Phase 2-4）

```

---

## 📊 構成サマリー

| # | セクション | ディレクトリ | ファイル数 | 対象読者 |
|----|-----------|----------|----------|--------|
| 0 | 基本設計 | - | 2 | 全員 |
| 1 | トップページ | 🏠_HOME | 3 | 開発・PO |
| 2 | 詳細分析 | 📊_ANALYTICS | 2 | 開発・ユーザー |
| 3 | CSV削除管理 | 🗑️_UPLOAD_MANAGER | 3 | 開発 |
| 4 | キーワード管理 | 🏷️_CATEGORY_RULES | 9 | 開発・デザイナー・ユーザー |
| 5 | 統合・拡張 | 📚_INTEGRATION | 3 | アーキテクト・PO |
| | **合計** | | **22** | |
| | **目安ページ数** | | **70-90p** | |

---

## 🔍 各セクションの概要

### **セクション 0: 基本設計** (2ファイル)

#### `00_MASTER_INDEX.md` (このファイル)
全体構成ガイド・インデックス

#### `01_MASTER_ARCHITECTURE.md`
マスタデータシステム全体：
- マスタの定義と重要性
- 4つのマスタの種類・役割
- ER図と関係図
- 全4ページでの使用方法

---

### **セクション 1: 🏠 トップページ (Home)** (3ファイル)

CSV読込→グラフ表示で必要なマスタ

```
Home (HomePage.vue)
├─ CSV Upload
├─ ExpenseChart
└─ SummaryCards
     ↓
  必要なマスタ: Categories（カテゴリ）
```

**ファイル**:
- `01_category_overview.md` - カテゴリ仕様・一覧
- `02_category_definitions.md` - 8カテゴリ詳細
- `03_category_db_schema.md` - DB定義・SQL

---

### **セクション 2: 📊 詳細分析 (Analytics)** (2ファイル)

カテゴリ別検索・手動修正で必要なマスタ

```
Analytics (AnalyticsPage.vue)
├─ CategoryTag（カテゴリ手動修正）
├─ Transaction Table（フィルタ・検索）
└─ 統計グラフ
     ↓
  必要なマスタ: Categories（フィルタ・修正対象）
```

**ファイル**:
- `01_analytics_requirements.md` - フィルタ・検索仕様
- `02_category_modification.md` - カテゴリ修正仕様

---

### **セクション 3: 🗑️ CSV削除管理 (Upload Manager)** (3ファイル)

ファイル履歴管理で必要なマスタ

```
UploadManager (モーダル)
├─ Upload History List
├─ Delete Function
└─ File Info Display
     ↓
  必要なマスタ: UploadHistories（履歴管理）
```

**ファイル**:
- `01_upload_history_spec.md` - 履歴仕様
- `02_upload_history_db_schema.md` - DB定義
- `03_file_management.md` - ファイル処理ロジック

---

### **セクション 4: 🏷️ キーワード管理 (Category Rules)** ★最重要 (9ファイル)

ルール追加・編集・削除で必要なマスタ

```
CategoryRulesPage (🏷️メニュー)
├─ Rule List Display
├─ Add/Edit Form
├─ Delete Function
└─ Bulk Operations
     ↓
  必要なマスタ: CategoryRules（分類ルール）
            + Categories（ルール対象）
```

**ファイル**:
- `01_rule_concept.md` - ルール基本概念
- `02_rule_structure.md` - プロパティ定義
- `03_matching_logic.md` - マッチングアルゴリズム
- `04_initial_rules.md` - 初期ルール（全8カテゴリ）
- `05_rule_db_schema.md` - DB定義
- `06_ui_requirements.md` - UI要件
- `07_api_specification.md` - API仕様
- `08_operation_guide.md` - 操作マニュアル
- `09_maintenance.md` - 監視・メンテナンス

---

### **セクション 5: 📚 統合・拡張 (3ファイル)

全マスタを統合した視点

```
全体ER図
├─ Categories (8個)
├─ CategoryRules (N個)
├─ Transactions (M個)
└─ UploadHistories (L個)
     ↓
  関係管理・ライフサイクル・拡張計画
```

**ファイル**:
- `01_data_relationships.md` - マスタ関係図・ER図
- `02_master_lifecycle.md` - ライフサイクル・フロー
- `03_extension_roadmap.md` - Phase 2-4 計画

---

## 🎯 読む順序（推奨）

### **🟢 初回閲覧（30分）**
1. このファイル（00_MASTER_INDEX.md）
2. `01_MASTER_ARCHITECTURE.md` - マスタ全体像

### **🟡 概要理解（45分）**
3. 🏠_HOME/01_category_overview.md
4. 📊_ANALYTICS/01_analytics_requirements.md
5. 🗑️_UPLOAD_MANAGER/01_upload_history_spec.md
6. 🏷️_CATEGORY_RULES/01_rule_concept.md

### **🟠 詳細理解（1.5時間）**
7. 🏠_HOME/02_category_definitions.md
8. 🏷️_CATEGORY_RULES/02_rule_structure.md
9. 🏷️_CATEGORY_RULES/03_matching_logic.md
10. 🏷️_CATEGORY_RULES/04_initial_rules.md

### **🔴 開発準備（2時間）**
11. 各セクション/XX_db_schema.md（3ファイル）
12. 🏷️_CATEGORY_RULES/07_api_specification.md

### **🟣 実装前（1.5時間）**
13. 🏷️_CATEGORY_RULES/06_ui_requirements.md
14. 🏷️_CATEGORY_RULES/08_operation_guide.md

### **⚪ 統合・運用（1時間）**
15. 📚_INTEGRATION/01_data_relationships.md
16. 🏷️_CATEGORY_RULES/09_maintenance.md

### **⬜ 今後の計画（オプション）**
17. 📚_INTEGRATION/02_master_lifecycle.md
18. 📚_INTEGRATION/03_extension_roadmap.md

---

## 📋 各セクションのREADME

各セクションに README.md を配置（セクション内の概要・ガイド）

```
🏠_HOME/README.md
├─ トップページで使用されるマスタ
├─ ファイル一覧・役割
└─ 推奨読了順���

📊_ANALYTICS/README.md
├─ 詳細分析で使用されるマスタ
├─ ファイル一覧・役割
└─ 推奨読了順序

🗑️_UPLOAD_MANAGER/README.md
├─ CSV削除管理で使用されるマスタ
├─ ファイル一覧・役割
└─ 推奨読了順序

🏷️_CATEGORY_RULES/README.md  ★最重要
├─ キーワード管理で使用されるマスタ
├─ ファイル一覧・役割
├─ 推奨読了順序
└─ 開発チェックリスト

📚_INTEGRATION/README.md
├─ マスタシステム統合
├─ 関係図・ライフサイクル
└─ 拡張計画
```

---

## 🔗 4つのページの関係図

```
┌─────────────────────────────────────────────────────┐
│                  Budget Book App                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  🏠_HOME               📊_ANALYTICS                 │
│  ─────────            ────────────                  │
│  CSV読込              カテゴリ手動修正              │
│  グラフ表示            詳細検索・分析               │
│      ↓                    ↓                         │
│  Categories           Categories                    │
│  (read-only)          (修正可能)                   │
│                                                     │
│  🗑️_UPLOAD_MANAGER    🏷️_CATEGORY_RULES ★重要     │
│  ───────────────      ──────────────────           │
│  CSV履歴管理           ルール管理                    │
│  ファイル削除          キーワード↔カテゴリ          │
│      ↓                    ↓                         │
│  UploadHistories      CategoryRules                 │
│  Transactions         (ユーザー編集)                │
│                                                     │
└─────────────────────────────────────────────────────┘
            ↓ すべてを統合
         📚_INTEGRATION
         ─────────────
         ER図・関係図・ライフサイクル
```

---

## ✅ 確認事項

このディレクトリ構成で実装を進めてよいですか？

- [ ] 4つのページごとにディレクトリ分割 ✅
  - 🏠_HOME
  - 📊_ANALYTICS
  - 🗑️_UPLOAD_MANAGER
  - 🏷️_CATEGORY_RULES
  - 📚_INTEGRATION

- [ ] 各セクションに README.md を配置 ✅

- [ ] ファイル22個の構成 ✅

- [ ] 推奨読了順序が明確 ✅

- [ ] マスタ間の関係が可視化されている ✅

---

## 🚀 次のステップ

このインデックスが確定したら、**Phase 2** で各セクション内のファイルを順番に作成していきます：

1. **基本設計** (01_MASTER_ARCHITECTURE.md)
2. **🏠_HOME/** (3ファイル)
3. **📊_ANALYTICS/** (2ファイル)
4. **🗑️_UPLOAD_MANAGER/** (3ファイル)
5. **🏷️_CATEGORY_RULES/** (9ファイル) ★優先度最高
6. **📚_INTEGRATION/** (3ファイル)

**確認してください！** 👇

