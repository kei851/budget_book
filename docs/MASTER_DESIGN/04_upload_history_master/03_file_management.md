# ファイル管理仕様書 - アップロード履歴マスタ用

**バージョン**: 1.0  
**作成日**: 2025 年 10 月 31 日  
**更新日**: 2025 年 11 月 5 日

---

## 📋 目次

1. [概要](#1-概要)
2. [ファイルハッシュ管理](#2-ファイルハッシュ管理)
3. [重複チェック仕様](#3-重複チェック仕様)
4. [エンコーディング検出ロジック](#4-エンコーディング検出ロジック)
5. [BOM 処理・文字変換](#5-bom-処理文字変換)

---

## 1. 概要

### 1.1 ファイル管理の目的

CSV ファイルのアップロード時に、以下の処理を実施します：

- 🔍 **重複チェック**: 同じファイルの再アップロードを防止
- 📝 **エンコーディング検出**: ファイルの文字コードを自動検出・変換
- 🧹 **BOM 処理**: BOM（Byte Order Mark）の除去
- 🔐 **ハッシュ計算**: ファイル内容のハッシュ値を計算

### 1.2 処理フロー

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
   → エンコーディング検出・変換
   → BOM 除去
   → CSV 解析
   ↓
5. データインポート
```

---

## 2. ファイルハッシュ管理

### 2.1 ハッシュアルゴリズム

**使用アルゴリズム**: MD5（Message Digest 5）

**理由**:
- 高速な計算速度
- 32 文字の固定長（保存に適している）
- ファイル内容の同一性チェックに十分

**注意**: MD5 はセキュリティ用途には適していませんが、ファイルの同一性チェックには問題ありません。

### 2.2 ハッシュ計算方法

#### 2.2.1 Ruby での実装

```ruby
# ファイル内容を読み取り
file_content = params[:csv_file].read

# MD5 ハッシュを計算
file_hash = Digest::MD5.hexdigest(file_content)

# ファイル読み込み位置をリセット（後続処理のため）
params[:csv_file].rewind
```

#### 2.2.2 ハッシュ値の形式

- **形式**: 16 進数 32 文字
- **例**: `abc123def45678901234567890123456`
- **大文字/小文字**: 小文字で保存

### 2.3 ハッシュの保存

#### 2.3.1 データベース保存

```ruby
# UploadHistory レコード作成時に保存
upload_history = UploadHistory.create!(
  filename: params[:csv_file].original_filename,
  upload_date: Time.current,
  file_hash: file_hash  # MD5 ハッシュを保存
)
```

#### 2.3.2 インデックス

```sql
-- 重複チェックを高速化するためのインデックス
CREATE INDEX idx_upload_histories_file_hash ON upload_histories(file_hash);
```

---

## 3. 重複チェック仕様

### 3.1 重複チェックの目的

- **データの重複防止**: 同じファイルを複数回インポートしない
- **ストレージ節約**: 不要なデータの蓄積を防止
- **ユーザー体験**: 誤って同じファイルをアップロードした場合に警告

### 3.2 重複チェック処理

#### 3.2.1 チェックフロー

```
1. ファイルアップロード
   ↓
2. ファイルハッシュ計算
   → file_hash = MD5(file_content)
   ↓
3. 既存レコード検索
   → UploadHistory.find_by(file_hash: file_hash)
   ↓
4. 重複判定
   ├─ 既存レコードあり → エラーレスポンス
   └─ 既存レコードなし → インポート処理続行
```

#### 3.2.2 実装例

```ruby
# app/controllers/api/v1/transactions_controller.rb

def import
  # ファイルハッシュ計算
  file_hash = Digest::MD5.hexdigest(params[:csv_file].read)
  params[:csv_file].rewind
  
  # 重複チェック
  existing_upload = UploadHistory.find_by(file_hash: file_hash)
  if existing_upload
    Rails.logger.info "Duplicate file detected: #{params[:csv_file].original_filename}"
    
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
  
  # インポート処理続行...
end
```

### 3.3 エラーレスポンス

#### 3.3.1 エラーメッセージ

```json
{
  "error": "このファイルは既にアップロード済みです",
  "existing_upload": {
    "filename": "rakuten_card_2025_10.csv",
    "upload_date": "2025-10-31T14:30:00.000Z",
    "imported_count": 150
  }
}
```

#### 3.3.2 ユーザーへの通知

- **フロントエンド**: エラーメッセージを表示
- **既存アップロード情報**: 既にアップロードされたファイルの情報を表示
- **オプション**: 既存データを削除して再インポートするオプション（将来的に検討）

---

## 4. エンコーディング検出ロジック

### 4.1 対応エンコーディング

| エンコーディング | 説明 | 検出方法 |
|----------------|------|---------|
| **UTF-8** | Unicode（UTF-8） | BOM 検出、または有効性チェック |
| **UTF-8 with BOM** | UTF-8 + BOM | BOM 検出（`\xEF\xBB\xBF`） |
| **UTF-16LE** | UTF-16 リトルエンディアン | BOM 検出（`\xFF\xFE`） |
| **UTF-16BE** | UTF-16 ビッグエンディアン | BOM 検出（`\xFE\xFF`） |
| **Shift_JIS** | 日本語文字コード | UTF-8 として無効な場合 |

### 4.2 エンコーディング検出フロー

```
1. ファイル内容をバイナリとして読み取り
   → content.force_encoding('BINARY')
   ↓
2. BOM 検出
   ├─ UTF-8 BOM → UTF-8 として処理
   ├─ UTF-16LE BOM → UTF-16LE → UTF-8 変換
   ├─ UTF-16BE BOM → UTF-16BE → UTF-8 変換
   └─ BOM なし → 次のステップ
   ↓
3. エンコーディング推測
   ├─ UTF-8 として試行
   │  ├─ 有効 → UTF-8 として処理
   │  └─ 無効 → Shift_JIS として変換
   └─ Shift_JIS → UTF-8 変換
```

### 4.3 実装例

#### 4.3.1 CsvImportService での処理

```ruby
# app/services/csv_import_service.rb

def import
  # ファイル内容を読み取り
  content = @csv_file.read
  
  # 強制的にバイナリとして読み取り
  content = content.force_encoding('BINARY')
  
  # BOM 検出・除去
  if content.start_with?("\xEF\xBB\xBF".force_encoding('BINARY'))
    # UTF-8 BOM
    content = content[3..-1]
    content = content.force_encoding('UTF-8')
  elsif content.start_with?("\xFF\xFE".force_encoding('BINARY'))
    # UTF-16LE BOM
    content = content[2..-1]
    content = content.force_encoding('UTF-16LE').encode('UTF-8')
  elsif content.start_with?("\xFE\xFF".force_encoding('BINARY'))
    # UTF-16BE BOM
    content = content[2..-1]
    content = content.force_encoding('UTF-16BE').encode('UTF-8')
  else
    # BOM なし、エンコーディング推測
    begin
      content = content.force_encoding('UTF-8')
      unless content.valid_encoding?
        # UTF-8 として無効な場合、Shift_JIS として変換
        content = content.force_encoding('Shift_JIS').encode('UTF-8')
      end
    rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
      # Shift_JIS でも変換できない場合、NKF を使用
      content = NKF.nkf('-w -S', content.force_encoding('BINARY'))
    end
  end
  
  # 以降の処理...
end
```

### 4.4 エンコーディング変換の注意点

#### 4.4.1 文字化け防止

- **BOM 検出**: BOM を確実に除去
- **エンコーディング推測**: UTF-8 → Shift_JIS の順で試行
- **フォールバック**: NKF を使用した最終的な変換

#### 4.4.2 パフォーマンス

- **一度だけ読み取り**: ファイル内容は一度だけ読み取り、メモリに保持
- **効率的な変換**: 必要最小限の変換処理

---

## 5. BOM 処理・文字変換

### 5.1 BOM（Byte Order Mark）とは

**BOM** は、ファイルの先頭に付加される特殊なマーカーで、エンコーディングを示します。

| BOM | バイト列 | エンコーディング |
|-----|---------|----------------|
| UTF-8 BOM | `\xEF\xBB\xBF` | UTF-8 |
| UTF-16LE BOM | `\xFF\xFE` | UTF-16LE |
| UTF-16BE BOM | `\xFE\xFF` | UTF-16BE |

### 5.2 BOM 除去処理

#### 5.2.1 UTF-8 BOM 除去

```ruby
if content.start_with?("\xEF\xBB\xBF".force_encoding('BINARY'))
  # BOM を除去（最初の 3 バイトを削除）
  content = content[3..-1]
  content = content.force_encoding('UTF-8')
end
```

#### 5.2.2 UTF-16LE BOM 除去

```ruby
if content.start_with?("\xFF\xFE".force_encoding('BINARY'))
  # BOM を除去（最初の 2 バイトを削除）
  content = content[2..-1]
  # UTF-16LE → UTF-8 変換
  content = content.force_encoding('UTF-16LE').encode('UTF-8')
end
```

#### 5.2.3 UTF-16BE BOM 除去

```ruby
if content.start_with?("\xFE\xFF".force_encoding('BINARY'))
  # BOM を除去（最初の 2 バイトを削除）
  content = content[2..-1]
  # UTF-16BE → UTF-8 変換
  content = content.force_encoding('UTF-16BE').encode('UTF-8')
end
```

### 5.3 文字変換処理

#### 5.3.1 半角カタカナ → 全角カタカナ変換

```ruby
# NKF を使用して半角カタカナを全角カタカナに変換
# -Z1 オプション: 半角カタカナを全角カタカナに変換
content = NKF.nkf('-w -Z1', content)
```

**理由**: キーワードマッチングの精度向上

**例**:
- 変換前: `セブン-イレブン`
- 変換後: `セブンイレブン`

#### 5.3.2 改行コード統一

```ruby
# 改行コードを統一（LF に統一）
content = content.gsub(/\r\n/, "\n").gsub(/\r/, "\n")
# 余分な空行を除去
content = content.strip
```

**理由**: プラットフォーム間の違いを吸収（Windows: `\r\n`, Mac: `\r`, Unix: `\n`）

### 5.4 データソース判定

#### 5.4.1 楽天カード CSV

```ruby
if first_line.include?('利用日')
  @data_source_type = 'rakuten'
end
```

**特徴**: 1 行目に「利用日」が含まれる

#### 5.4.2 エポスカード CSV

```ruby
if first_line.include?('ご利用年月日') || second_line.include?('ご利用年月日')
  @data_source_type = 'epos'
  # エポスカードは 1 行目がタイトル行なのでスキップ
  lines.shift
  content = lines.join("\n")
end
```

**特徴**: 1 行目または 2 行目に「ご利用年月日」が含まれる、1 行目がタイトル行

---

## 6. まとめ

### 6.1 ファイル管理の重要性

ファイル管理機能は、以下の目的で重要です：

- **データ整合性**: 重複データの防止
- **文字化け防止**: エンコーディングの適切な処理
- **ユーザー体験**: スムーズなインポート処理

### 6.2 実装のポイント

- **ハッシュ計算**: ファイル内容の同一性チェック
- **エンコーディング検出**: 自動検出・変換により文字化けを防止
- **BOM 処理**: BOM の確実な除去
- **エラーハンドリング**: 適切なエラーメッセージ表示

### 6.3 次のステップ

- [01_upload_history_spec.md](./01_upload_history_spec.md) - アップロード履歴仕様
- [02_upload_history_db_schema.md](./02_upload_history_db_schema.md) - DB スキーマ

---

**📝 備考**: このドキュメントは、CSV ファイルの管理処理（ハッシュ・エンコーディング・BOM）の仕様を定義しています。実際の実装では、`CsvImportService` クラスを参照してください。

