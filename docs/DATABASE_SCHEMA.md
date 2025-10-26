# Budget Book - データベース設計図

## データモデル関係図

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'fontSize': '16px', 'fontFamily': 'arial'}, 'er': {'fontSize': '16px'}}}%%
erDiagram
    CATEGORIES ||--o{ TRANSACTIONS : has
    CATEGORIES ||--o{ CATEGORY_RULES : has
    CATEGORIES ||--o{ CATEGORY_KEYWORDS : has
    UPLOAD_HISTORIES ||--o{ TRANSACTIONS : contains

    CATEGORIES {
        int id PK
        string name UK
        string color
        string icon
        string description
        int display_order
        timestamp created_at
        timestamp updated_at
    }

    TRANSACTIONS {
        int id PK
        int category_id FK
        date transaction_date
        string store_name
        decimal amount "12,2"
        string payment_method
        string user_name
        string payment_month
        int upload_history_id FK
        boolean auto_classified
        text raw_data
        timestamp created_at
        timestamp updated_at
    }

    CATEGORY_RULES {
        int id PK
        int category_id FK
        string keyword UK
        int priority
        timestamp created_at
        timestamp updated_at
    }

    CATEGORY_KEYWORDS {
        int id PK
        int category_id FK
        string keyword
        int priority
        timestamp created_at
        timestamp updated_at
    }

    UPLOAD_HISTORIES {
        int id PK
        string filename
        datetime upload_date
        int imported_count
        string file_hash
        string data_source_type
        string description
        timestamp created_at
        timestamp updated_at
    }
```

## テーブル詳細図

### Categories テーブル

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'fontSize': '16px', 'fontFamily': 'arial'}, 'flowchart': {'htmlLabels': true}}}%%
graph TD
    CAT["📊 categories<br/>━━━━━━━━━━━━━━━━━━<br/><b>カテゴリマスタ</b><br/>━━━━━━━━━━━━━━━━━━<br/>id (PK)<br/>name (UNIQUE)<br/>color<br/>icon<br/>description<br/>display_order<br/>━━━━━━━━━━━━━━━━━━<br/>インデックス:<br/>• name (UNIQUE)<br/>• display_order"]

    Transactions["Transactions"]
    Rules["CategoryRules"]
    Keywords["CategoryKeywords"]

    CAT -->|1:N| Transactions
    CAT -->|1:N| Rules
    CAT -->|1:N| Keywords

    style CAT fill:#ce93d8,stroke:#4a148c,stroke-width:2px
    style Transactions fill:#b3e5fc
    style Rules fill:#b3e5fc
    style Keywords fill:#b3e5fc
```

### Transactions テーブル

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'fontSize': '14px', 'fontFamily': 'arial'}, 'flowchart': {'htmlLabels': true}}}%%
graph TD
    TX["📝 transactions<br/>━━━━━━━━━━━━━━━━━━━━━<br/><b>取引記録</b><br/>━━━━━━━━━━━━━━━━━━━━━<br/>id (PK)<br/>category_id (FK, optional)<br/>transaction_date<br/>store_name (max 500)<br/>amount (Decimal)<br/>payment_method<br/>user_name<br/>payment_month<br/>auto_classified (boolean)<br/>upload_history_id (FK)<br/>raw_data (Text)<br/>━━━━━━━━━━━━━━━━━━━━━<br/>インデックス:<br/>• category_id<br/>• transaction_date<br/>• amount<br/>• upload_history_id<br/>• (transaction_date + amount)<br/>━━━━━━━━━━━━━━━━━━━━━"]

    CAT["Categories"]
    UH["UploadHistories"]

    TX -->|FK| CAT
    TX -->|FK| UH

    style TX fill:#b3e5fc,stroke:#01579b,stroke-width:2px
    style CAT fill:#ce93d8,stroke:#4a148c,stroke-width:1px
    style UH fill:#f8bbd0,stroke:#880e4f,stroke-width:1px
```

### CategoryRules テーブル

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'fontSize': '14px', 'fontFamily': 'arial'}, 'flowchart': {'htmlLabels': true}}}%%
graph TD
    RULE["🏷️ category_rules<br/>━━━━━━━━━━━━━━━━<br/><b>分類ルール</b><br/>━━━━━━━━━━━━━━━━<br/>id (PK)<br/>category_id (FK)<br/>keyword (UNIQUE)<br/>priority (Integer)<br/>━━━━━━━━━━━━━━━━<br/>インデックス:<br/>• category_id<br/>• keyword<br/>• priority<br/>━━━━━━━━━━━━━━━━<br/><b>用途:</b><br/>CSV インポート時に<br/>store_name を照合して<br/>自動でカテゴリを判定"]

    CAT["Categories"]
    RULE -->|FK| CAT

    style RULE fill:#ffe0b2,stroke:#e65100,stroke-width:2px
    style CAT fill:#ce93d8,stroke:#4a148c,stroke-width:1px
```

### UploadHistories テーブル

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'fontSize': '14px', 'fontFamily': 'arial'}, 'flowchart': {'htmlLabels': true}}}%%
graph TD
    UH["📂 upload_histories<br/>━━━━━━━━━━━━━━━━━━<br/><b>アップロード履歴</b><br/>━━━━━━━━━━━━━━━━━━<br/>id (PK)<br/>filename<br/>upload_date<br/>imported_count<br/>file_hash (MD5)<br/>data_source_type<br/>   (rakuten|epos)<br/>description<br/>━━━━━━━━━━━━━━━━━━<br/>インデックス:<br/>• file_hash<br/>• upload_date<br/>━━━━━━━━━━━━━━━━━━<br/><b>用途:</b><br/>重複ファイル検出<br/>インポート履歴管理"]

    TX["Transactions"]
    UH -->|1:N| TX

    style UH fill:#f8bbd0,stroke:#880e4f,stroke-width:2px
    style TX fill:#b3e5fc,stroke:#01579b,stroke-width:1px
```

## データフロー：スキーマの観点

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'fontSize': '16px', 'fontFamily': 'arial'}, 'flowchart': {'htmlLabels': true}}}%%
graph TB
    subgraph Import["CSV インポート処理"]
        File["CSV ファイル"]
        Parse["Parse & Classify"]
        ValidTx["Validate"]
    end

    subgraph Storage["データ保存"]
        UH["UploadHistory<br/>作成"]
        TX["Transaction<br/>作成"]
        RuleRef["CategoryRule<br/>参照"]
    end

    subgraph Query["データ検索・集計"]
        GetTx["Transaction 取得"]
        GroupCat["カテゴリで<br/>グループ化"]
        Sum["金額を合計"]
    end

    File --> Parse
    Parse --> RuleRef
    RuleRef --> ValidTx
    ValidTx --> UH
    ValidTx --> TX

    GetTx --> GroupCat
    TX -->|SELECT| GetTx
    GroupCat -->|JOIN categories| GroupCat
    GroupCat --> Sum

    style File fill:#c8e6c9
    style Parse fill:#fff9c4
    style RuleRef fill:#f3e5f5
    style ValidTx fill:#c8e6c9
    style UH fill:#f8bbd0
    style TX fill:#b3e5fc
    style GetTx fill:#b3e5fc
    style GroupCat fill:#ffe0b2
    style Sum fill:#ffb74d
```

## インデックス戦略

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'fontSize': '16px', 'fontFamily': 'arial'}, 'flowchart': {'htmlLabels': true}}}%%
graph TB
    subgraph TxIndexes["Transactions インデックス"]
        Idx1["<b>category_id</b><br/>━━━━━━━━━━<br/>用途: JOIN categories<br/>カテゴリフィルタ"]
        Idx2["<b>transaction_date</b><br/>━━━━━━━━━━<br/>用途: 期間検索<br/>月別・日別集計"]
        Idx3["<b>amount</b><br/>━━━━━━━━━━<br/>用途: 金額範囲検索<br/>金額でのソート"]
        Idx4["<b>upload_history_id</b><br/>━━━━━━━━━━<br/>用途: ファイル削除時<br/>連鎖削除"]
        Idx5["<b>(transaction_date + amount)</b><br/>━━━━━━━━━━<br/>用途: 複合条件検索<br/>日付 & 金額"]
    end

    subgraph CatIndexes["Categories インデックス"]
        CIdx1["<b>name (UNIQUE)</b><br/>━━━━━━━<br/>用途: 重複防止<br/>カテゴリ名検索"]
        CIdx2["<b>display_order</b><br/>━━━━━━━<br/>用途: ソート"]
    end

    subgraph RuleIndexes["CategoryRules インデックス"]
        RIdx1["<b>category_id</b><br/>━━━━━━━<br/>用途: カテゴリ別<br/>ルール取得"]
        RIdx2["<b>keyword (UNIQUE)</b><br/>━━━━━━━<br/>用途: 重複防止<br/>キーワード検索"]
        RIdx3["<b>priority</b><br/>━━━━━━━<br/>用途: 優先度順<br/>マッチング"]
    end

    subgraph UHIndexes["UploadHistories インデックス"]
        UIdx1["<b>file_hash</b><br/>━━━━━━━<br/>用途: 重複検出"]
        UIdx2["<b>upload_date</b><br/>━━━━━━━<br/>用途: 履歴検索"]
    end

    style TxIndexes fill:#b3e5fc,stroke:#01579b,stroke-width:2px
    style CatIndexes fill:#ce93d8,stroke:#4a148c,stroke-width:2px
    style RuleIndexes fill:#ffe0b2,stroke:#e65100,stroke-width:2px
    style UHIndexes fill:#f8bbd0,stroke:#880e4f,stroke-width:2px
```

## リレーション詳細

### Category → Transaction

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'fontSize': '16px', 'fontFamily': 'arial'}, 'flowchart': {'htmlLabels': true}}}%%
graph LR
    Cat["Category<br/>id=3<br/>name=食費<br/>color=#4BC0C0"]

    Tx1["Transaction<br/>id=10<br/>category_id=3<br/>amount=3000"]
    Tx2["Transaction<br/>id=11<br/>category_id=3<br/>amount=2500"]
    Tx3["Transaction<br/>id=12<br/>category_id=3<br/>amount=1800"]
    TxNull["Transaction<br/>id=13<br/>category_id=NULL<br/>(未分類)"]

    Cat -->|1:N| Tx1
    Cat -->|1:N| Tx2
    Cat -->|1:N| Tx3
    Cat -.->|optional| TxNull

    style Cat fill:#ce93d8,stroke:#4a148c,stroke-width:2px
    style Tx1 fill:#b3e5fc,stroke:#01579b,stroke-width:1px
    style Tx2 fill:#b3e5fc,stroke:#01579b,stroke-width:1px
    style Tx3 fill:#b3e5fc,stroke:#01579b,stroke-width:1px
    style TxNull fill:#ffccbc,stroke:#d84315,stroke-width:1px
```

### UploadHistory → Transaction (Cascade Delete)

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'fontSize': '16px', 'fontFamily': 'arial'}, 'flowchart': {'htmlLabels': true}}}%%
graph LR
    UH["UploadHistory<br/>id=5<br/>filename=202410.csv<br/>imported_count=86"]

    Tx1["Transaction<br/>upload_history_id=5"]
    Tx2["Transaction<br/>upload_history_id=5"]
    Tx3["Transaction<br/>upload_history_id=5"]

    UH -->|1:N<br/>dependent:destroy| Tx1
    UH -->|1:N<br/>dependent:destroy| Tx2
    UH -->|1:N<br/>dependent:destroy| Tx3

    DeleteUH["UploadHistory<br/>削除"]
    DeleteUH -.->|削除時に自動削除| Tx1
    DeleteUH -.->|削除時に自動削除| Tx2
    DeleteUH -.->|削除時に自動削除| Tx3

    style UH fill:#f8bbd0,stroke:#880e4f,stroke-width:2px
    style Tx1 fill:#b3e5fc,stroke:#01579b,stroke-width:1px
    style Tx2 fill:#b3e5fc,stroke:#01579b,stroke-width:1px
    style Tx3 fill:#b3e5fc,stroke:#01579b,stroke-width:1px
    style DeleteUH fill:#ffccbc,stroke:#d84315,stroke-width:2px
```

## スケーリング戦略

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'fontSize': '16px', 'fontFamily': 'arial'}, 'flowchart': {'htmlLabels': true}}}%%
graph TB
    Current["現在<br/>SQLite3<br/>単一ファイル<br/>同期処理"]

    Phase1["フェーズ1<br/>PostgreSQL<br/>マルチユーザー<br/>トランザクション"]

    Phase2["フェーズ2<br/>Redis Cache<br/>クエリ結果<br/>セッション"]

    Phase3["フェーズ3<br/>Sidekiq<br/>背景ジョブ化<br/>CSV処理非同期化"]

    Current --> Phase1
    Phase1 --> Phase2
    Phase2 --> Phase3

    style Current fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    style Phase1 fill:#ffe0b2,stroke:#e65100,stroke-width:2px
    style Phase2 fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    style Phase3 fill:#c8e6c9,stroke:#1b5e20,stroke-width:2px
```
