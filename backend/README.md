# Backend

Rails 8 API mode による家計簿アプリのバックエンド。

## 起動

```bash
bundle install
rails db:migrate
rails db:seed
ANTHROPIC_API_KEY=your_key rails server -p 3001
```

## 構成

```
app/
├── controllers/api/v1/
│   ├── transactions_controller.rb      # 取引CRUD・CSV取込・月次集計・分析
│   ├── categories_controller.rb        # カテゴリ一覧
│   ├── category_rules_controller.rb    # 分類ルールCRUD・一括更新
│   ├── upload_histories_controller.rb  # アップロード履歴・削除
│   ├── budgets_controller.rb           # 月次予算管理
│   ├── insights_controller.rb          # 前月比較・定期支出検出
│   ├── asset_snapshots_controller.rb   # 資産残高の月次取得・保存・推移
│   └── ai_controller.rb               # AIチャット(SSE)・月次サマリ・再分類
├── models/
│   ├── transaction.rb
│   ├── category.rb                     # 7カテゴリ固定
│   ├── category_rule.rb               # after_save でCSV自動更新
│   ├── upload_history.rb
│   ├── budget.rb
│   ├── asset_account.rb               # 6口座固定マスタ
│   └── asset_snapshot.rb              # 月次残高スナップショット
└── services/
    ├── csv_import_service.rb           # 楽天カード/エポス/楽天銀行CSV対応
    ├── category_classifier_service.rb  # キーワードルールによる分類
    ├── ai_category_classifier_service.rb # AIによるバッチ分類
    └── ai_insight_service.rb          # チャットコンテキスト・月次サマリ生成
```

## 主要な設計メモ

**CSV取込（csv_import_service.rb）**
- ヘッダ行を見てデータソース（楽天カード/エポス/楽天銀行）を自動判定
- 楽天銀行: カード引き落とし行・ATM出金行・給与・利息を `rakuten_bank_skip?` でスキップ
- BOM付きUTF-8 / Shift_JIS を自動変換。半角カタカナは全角に正規化

**AIチャット（ai_controller.rb）**
- `record_transaction` ツールを使って支出をDBに保存
- `client.messages.create`（非ストリーミング）+ tools で呼び出し
- SSEで結果を返す（tool_use時は `{ type: "tool_result" }`、通常時はテキスト）

**資産管理（asset_snapshots_controller.rb）**
- 口座マスタ（asset_accounts）は固定6件。`AssetAccount.seed!` で初期投入
- 月次スナップショット（asset_snapshots）は `recorded_month` × `asset_account_id` でユニーク制約

**アップロード履歴（upload_history.rb）**
- `file_hash`（MD5）カラムで同一ファイルの二重インポートを検出・拒否
- `UploadHistory` を削除すると `dependent: :destroy` で紐づく `transactions` も連鎖削除される

**カテゴリルール（category_rule.rb）**
- `priority` カラム（整数）でルールの適用順序を制御。小さい値が優先
- `after_save` / `after_destroy` フックで `data/scripts/` 配下のCSVを自動更新

## API一覧

詳細は [docs/master_spec.md](../docs/master_spec.md) を参照。
