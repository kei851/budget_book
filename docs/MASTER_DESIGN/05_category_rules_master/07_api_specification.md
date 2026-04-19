# REST API 仕様 - 分類ルール管理用

**バージョン**: 1.0  
**作成日**: 2025 年 10 月 31 日  
**更新日**: 2025 年 11 月 5 日

---

## 📋 目次

1. [API エンドポイント一覧](#1-api-エンドポイント一覧)
2. [リクエスト/レスポンス仕様](#2-リクエストレスポンス仕様)
3. [エラーハンドリング](#3-エラーハンドリング)

---

## 1. API エンドポイント一覧

| メソッド | エンドポイント | 説明 |
|---------|--------------|------|
| GET | `/api/v1/category_rules` | ルール一覧取得 |
| POST | `/api/v1/category_rules` | ルール作成 |
| PATCH | `/api/v1/category_rules/:id` | ルール更新 |
| DELETE | `/api/v1/category_rules/:id` | ルール削除 |

---

## 2. リクエスト/レスポンス仕様

### 2.1 ルール一覧取得

```
GET /api/v1/category_rules

レスポンス:
{
  "category_rules": [
    {
      "id": 1,
      "keyword": "セブン",
      "category_id": 2,
      "category_name": "食費",
      "category_color": "#4BC0C0",
      "priority": 105,
      "matching_count": 45,
      "created_at": "2025-10-31T14:30:00.000Z",
      "updated_at": "2025-10-31T14:30:00.000Z"
    }
  ]
}
```

### 2.2 ルール作成

```
POST /api/v1/category_rules

リクエスト:
{
  "category_rule": {
    "keyword": "新しいキーワード",
    "category_id": 2,
    "priority": 80
  }
}

レスポンス:
{
  "id": 999,
  "keyword": "新しいキーワード",
  "category_id": 2,
  "category_name": "食費",
  "category_color": "#4BC0C0",
  "priority": 80
}
```

### 2.3 ルール更新

```
PATCH /api/v1/category_rules/:id

リクエスト:
{
  "category_rule": {
    "priority": 110
  }
}

レスポンス:
{
  "id": 1,
  "keyword": "セブン",
  "category_id": 2,
  "priority": 110
}
```

### 2.4 ルール削除

```
DELETE /api/v1/category_rules/:id

レスポンス:
{
  "message": "ルールを削除しました"
}
```

---

## 3. エラーハンドリング

### 3.1 エラーコード

| HTTP ステータス | 説明 | 例 |
|---------------|------|-----|
| 400 | バリデーションエラー | キーワードが空 |
| 404 | リソースが見つからない | ルール ID が存在しない |
| 422 | 処理不可 | UNIQUE 制約違反 |
| 500 | サーバーエラー | 予期しないエラー |

---

**📝 備考**: このドキュメントは、分類ルール管理の API 仕様を定義しています。実際の実装では、`backend/app/controllers/api/v1/category_rules_controller.rb` を参照してください。

