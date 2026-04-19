# アップロード履歴マスタ仕様書

**バージョン**: 1.0  
**作成日**: 2025 年 10 月 31 日  
**更新日**: 2025 年 11 月 5 日

---

## 📋 目次

1. [目的](#1-目的)
2. [プロパティ定義](#2-プロパティ定義)
3. [画面仕様](#3-画面仕様)
4. [機能要件](#4-機能要件)

---

## 1. 目的

### 1.1 アップロード履歴マスタの役割

**アップロード履歴マスタ**（`upload_histories`）は、CSV ファイルのアップロード履歴を管理するためのマスタデータです。

**主な目的**:
- 📂 **履歴管理**: アップロードされた CSV ファイルの履歴を記録
- 🔍 **重複防止**: 同じファイルの再アップロードを防止
- 🗑️ **データ削除**: アップロードされたデータを一括削除
- 📊 **統計情報**: アップロード件数・インポート件数の追跡

### 1.2 使用箇所

- 🗑️ **UploadManager**: CSV 削除管理ページ
- **CSV インポート処理**: アップロード時の履歴作成・重複チェック

---

## 2. プロパティ定義

### 2.1 プロパティ一覧

| プロパティ名 | 型 | 制約 | 説明 |
|-----------|-----|------|------|
| `id` | INTEGER | PRIMARY KEY | 主キー |
| `filename` | VARCHAR | NOT NULL | アップロードされたファイル名 |
| `upload_date` | DATETIME | NOT NULL | アップロード日時 |
| `imported_count` | INTEGER | NOT NULL, >= 0 | インポートされた取引件数 |
| `file_hash` | VARCHAR | - | ファイルの MD5 ハッシュ（重複チェック用） |
| `data_source_type` | VARCHAR | NOT NULL, DEFAULT 'rakuten' | データソースタイプ（rakuten/epos） |
| `description` | TEXT | - | 備考・説明 |
| `created_at` | DATETIME | NOT NULL | 作成日時 |
| `updated_at` | DATETIME | NOT NULL | 更新日時 |

### 2.2 プロパティ詳細

#### filename（ファイル名）

- **型**: VARCHAR（255 文字まで）
- **制約**: NOT NULL
- **説明**: アップロードされた CSV ファイルの元のファイル名
- **例**: `rakuten_card_2025_10.csv`, `epos_2025_11.csv`
- **用途**: UI 表示、履歴識別

#### upload_date（アップロード日時）

- **型**: DATETIME
- **制約**: NOT NULL
- **説明**: ファイルがアップロードされた日時
- **形式**: ISO 8601 形式（`YYYY-MM-DD HH:MM:SS`）
- **タイムゾーン**: サーバーのタイムゾーン（JST）
- **用途**: 履歴の時系列ソート、表示

#### imported_count（インポート件数）

- **型**: INTEGER
- **制約**: NOT NULL, >= 0
- **説明**: この CSV ファイルからインポートされた取引データの件数
- **初期値**: 0
- **更新タイミング**: CSV インポート完了時
- **用途**: UI 表示、統計情報

#### file_hash（ファイルハッシュ）

- **型**: VARCHAR（32 文字、MD5 ハッシュ）
- **制約**: なし（NULL 可）
- **説明**: ファイル内容の MD5 ハッシュ値（重複チェック用）
- **計算方法**: `Digest::MD5.hexdigest(file_content)`
- **用途**: 重複ファイルの検出

#### data_source_type（データソースタイプ）

- **型**: VARCHAR（50 文字）
- **制約**: NOT NULL, DEFAULT 'rakuten'
- **説明**: CSV ファイルのデータソースタイプ
- **値**:
  - `rakuten`: 楽天カード CSV
  - `epos`: エポスカード CSV
- **用途**: CSV 解析ロジックの切り替え

#### description（説明）

- **型**: TEXT
- **制約**: なし（NULL 可）
- **説明**: 備考・説明文
- **用途**: ユーザーによるメモ、将来的な拡張

---

## 3. 画面仕様

### 3.1 UploadManager ページ

#### 3.1.1 ページ構成

```
┌─────────────────────────────────────┐
│  🗑️ アップロード履歴管理        [×] │
├─────────────────────────────────────┤
│  [全選択] [選択項目を削除 (N)]      │
├─────────────────────────────────────┤
│  ☐ 📄 rakuten_card_2025_10.csv      │
│     2025/10/31 14:30 JST  150件    │
├─────────────────────────────────────┤
│  ☑ 📄 epos_2025_11.csv              │
│     2025/11/01 09:15 JST  200件    │
├─────────────────────────────────────┤
│  ☐ 📄 rakuten_card_2025_11.csv      │
│     2025/11/05 10:20 JST  180件    │
└─────────────────────────────────────┘
```

#### 3.1.2 表示項目

| 項目 | 説明 | データソース |
|------|------|------------|
| **ファイル名** | CSV ファイル名 | `filename` |
| **アップロード日時** | アップロードされた日時 | `upload_date`（フォーマット済み） |
| **インポート件数** | インポートされた取引件数 | `imported_count` |

#### 3.1.3 表示順序

- **デフォルト**: `upload_date` 降順（新しい順）
- **スコープ**: `recent` scope を使用
  ```ruby
  scope :recent, -> { order(upload_date: :desc) }
  ```

### 3.2 UI 機能

#### 3.2.1 一覧表示

- **全選択/解除**: チェックボックスで全選択・解除
- **個別選択**: 各履歴項目を個別に選択可能
- **選択状態表示**: 選択された項目は視覚的にハイライト

#### 3.2.2 削除機能

- **一括削除**: 選択した複数の履歴を一度に削除
- **確認ダイアログ**: 削除前に確認ダイアログを表示
  - 削除対象ファイル数
  - 削除対象取引件数の合計
  - 警告メッセージ

---

## 4. 機能要件

### 4.1 アップロード時の処理

#### 4.1.1 履歴作成フロー

```
1. CSV ファイルアップロード
   ↓
2. ファイルハッシュ計算
   → MD5(file_content)
   ↓
3. 重複チェック
   → file_hash で既存レコード検索
   ↓
4. 重複なしの場合
   → UploadHistory レコード作成
   → filename, upload_date, file_hash を保存
   ↓
5. CSV インポート処理
   → CsvImportService でインポート
   ↓
6. インポート件数更新
   → imported_count を更新
```

#### 4.1.2 重複チェック

```ruby
# 重複チェック処理
file_hash = Digest::MD5.hexdigest(params[:csv_file].read)
params[:csv_file].rewind

existing_upload = UploadHistory.find_by(file_hash: file_hash)
if existing_upload
  # エラーレスポンス
  render json: {
    error: 'このファイルは既にアップロード済みです',
    existing_upload: {
      filename: existing_upload.filename,
      upload_date: existing_upload.upload_date,
      imported_count: existing_upload.imported_count
    }
  }, status: :unprocessable_entity
  return
end
```

### 4.2 削除時の処理

#### 4.2.1 削除フロー

```
1. ユーザーが履歴を選択
   ↓
2. 削除確認ダイアログ表示
   → 削除対象ファイル数
   → 削除対象取引件数合計
   ↓
3. ユーザーが確認
   ↓
4. API 呼び出し: DELETE /api/v1/upload_histories/:id
   ↓
5. カスケード削除
   → 関連する transactions も削除
   ↓
6. 削除完了
   → 履歴リストから削除
   → 親コンポーネントに通知
```

#### 4.2.2 カスケード削除

```ruby
# UploadHistory モデル
has_many :transactions, dependent: :destroy

# 削除時、関連する取引も自動削除される
upload_history.destroy
# => 関連する transactions も削除される
```

### 4.3 表示メソッド

#### 4.3.1 display_name

```ruby
# ファイル名と件数を表示
def display_name
  "#{filename} (#{imported_count}件)"
end
```

**使用例**:
- `rakuten_card_2025_10.csv (150件)`

#### 4.3.2 formatted_upload_date

```ruby
# アップロード日時を JST 形式で表示
def formatted_upload_date
  upload_date.in_time_zone("Asia/Tokyo").strftime("%Y/%m/%d %H:%M JST")
end
```

**使用例**:
- `2025/10/31 14:30 JST`

---

## 5. API 仕様

### 5.1 アップロード履歴一覧取得

```
GET /api/v1/upload_histories

レスポンス:
{
  "upload_histories": [
    {
      "id": 1,
      "filename": "rakuten_card_2025_10.csv",
      "upload_date": "2025-10-31T14:30:00.000Z",
      "imported_count": 150,
      "file_hash": "abc123def456...",
      "data_source_type": "rakuten",
      "description": null,
      "created_at": "2025-10-31T14:30:00.000Z",
      "updated_at": "2025-10-31T14:30:05.000Z"
    },
    ...
  ]
}
```

### 5.2 アップロード履歴削除

```
DELETE /api/v1/upload_histories/:id

レスポンス:
{
  "message": "アップロード履歴を削除しました",
  "deleted_transactions_count": 150
}
```

**注意**: カスケード削除により、関連する取引データも削除されます。

---

## 6. まとめ

### 6.1 アップロード履歴マスタの重要性

アップロード履歴マスタは、以下の目的で重要です：

- **データ管理**: アップロードされたデータの追跡
- **重複防止**: 同じファイルの再インポートを防止
- **データ削除**: 一括削除機能の実現
- **統計情報**: インポート件数の把握

### 6.2 次のステップ

- [02_upload_history_db_schema.md](./02_upload_history_db_schema.md) - データベーススキーマ
- [03_file_management.md](./03_file_management.md) - ファイル管理（ハッシュ・エンコーディング）

---

**📝 備考**: このドキュメントは、アップロード履歴マスタの仕様を定義しています。実際の実装では、エラーハンドリングとユーザーフィードバックを適切に実装してください。

