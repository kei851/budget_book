# 家計簿アプリ

楽天カード・エポスカード・楽天銀行のCSVを取り込んで支出を可視化し、AIと会話しながら管理できる個人用家計簿。

---

## 機能

### 支出管理
- **CSVインポート**: 楽天カード / エポスカード / 楽天銀行の明細を自動取込
- **重複排除フィルタ**: 楽天銀行CSVのカード引き落とし行・ATM出金行を自動スキップ
- **カテゴリ自動分類**: キーワードルール + AIによる二段階分類
- **インライン編集**: 取引テーブルからカテゴリを直接変更

### 分析（3タブ）
| タブ | 内容 |
|------|------|
| 概要 | 統計カード・円グラフ・日別折れ線・AIサマリ |
| インサイト | 月次予算・前月比較・定期支出検出 |
| 取引明細 | フィルタ付き取引テーブル |

### 資産管理
- 6口座（楽天銀行・ゆうちょ銀行・楽天証券・現金・PayPay・Pasmo）の月次残高を記録
- 総資産推移グラフ・前月比表示

### AIチャット（Claude）
- 右下の💬ボタンで開くフローティングパネル
- 「昨日コンビニで500円使った」→ 自動でDBに保存
- 家計アドバイス・支出分析の相談

---

## 技術スタック

| | |
|---|---|
| バックエンド | Ruby on Rails 8（API mode）, SQLite |
| フロントエンド | Vue 3 Composition API, Pug, SCSS, Vite, Chart.js |
| AI | Anthropic Claude API（claude-opus-4-5）|
| ポート | backend: 3001 / frontend: 3002 |

---

## セットアップ

```bash
# バックエンド
cd backend
bundle install
rails db:migrate
rails db:seed
ANTHROPIC_API_KEY=your_key rails server -p 3001

# フロントエンド（別ターミナル）
cd frontend
npm install
npm run dev
```

ブラウザで http://localhost:3002 を開く。

---

## 月次の使い方

**支出記録**
1. 楽天カードCSV → アップロード
2. エポスカードCSV → アップロード
3. 楽天銀行CSV → アップロード（重複行は自動スキップ）
4. 現金・Pasmo・PayPay払いは AIチャットで記録

**資産記録**
5. 月末に「資産管理」ページで6口座の残高を入力

**振り返り**
6. 「詳細分析」→「概要」タブのAIサマリで確認

---

## CSVフォーマット

| ソース | 判定ヘッダ | 取込対象 |
|--------|-----------|---------|
| 楽天カード | `利用日` | 全件 |
| エポスカード | `ご利用年月日` | 全件 |
| 楽天銀行 | `入出金(円)` | 出金のみ（カード引き落とし・ATM除く） |

エンコーディング: BOM付きUTF-8 / Shift_JIS を自動判定。半角カタカナは全角に正規化。

---

## カテゴリ

| ID | 名前 |
|----|------|
| 1 | 投資 |
| 2 | 食費 |
| 3 | 日用品費 |
| 4 | 娯楽費 |
| 5 | 住宅費 |
| 6 | 交通費 |
| 7 | その他 |

---

## プロジェクト構成

```
budget_book/
├── backend/
│   └── app/
│       ├── controllers/api/v1/
│       │   ├── transactions_controller.rb
│       │   ├── ai_controller.rb        # チャット・サマリ・再分類
│       │   ├── asset_snapshots_controller.rb
│       │   ├── budgets_controller.rb
│       │   └── insights_controller.rb
│       ├── models/
│       │   ├── transaction.rb
│       │   ├── category.rb
│       │   ├── category_rule.rb
│       │   ├── asset_account.rb
│       │   └── asset_snapshot.rb
│       └── services/
│           ├── csv_import_service.rb
│           ├── ai_category_classifier_service.rb
│           └── ai_insight_service.rb
├── frontend/src/
│   └── components/
│       ├── HomePage.vue
│       ├── AnalyticsPage.vue
│       ├── AssetPage.vue
│       ├── CategoryRulesPage.vue
│       └── AiChatPanel.vue
└── docs/
    ├── master_spec.md      # 機能・設計の全体仕様
    └── development_diary.md
```

---

## ドキュメント

- **[docs/master_spec.md](docs/master_spec.md)** — 機能仕様・データフロー・API一覧の全体像
