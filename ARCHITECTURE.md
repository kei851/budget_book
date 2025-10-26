# Budget Book - アーキテクチャ図

## 全体構成図

```mermaid
graph TB
    subgraph Frontend["🎨 フロントエンド層 (Vue.js 3 - Port 3002/5173)"]
        App["App.vue<br/>ルートコンポーネント"]
        Header["AppHeader<br/>ナビゲーション"]
        Menu["HamburgerMenu<br/>メニュー"]
        HomePage["HomePage<br/>ダッシュボード"]
        Analytics["AnalyticsPage<br/>詳細分析"]
        Rules["CategoryRulesPage<br/>ルール管理"]
        FileUp["FileUpload<br/>CSV選択"]
        Chart["ExpenseChart<br/>グラフ表示"]
        Summary["SummaryCards<br/>統計表示"]
        Upload["UploadManager<br/>モーダル"]

        App --> Header
        App --> HomePage
        App --> Analytics
        App --> Rules
        App --> Upload
        Header --> Menu
        HomePage --> FileUp
        HomePage --> Chart
        HomePage --> Summary
    end

    subgraph API["🔌 API通信"]
        ApiService["api.js<br/>シングルトンサービス<br/>18エンドポイント"]
    end

    subgraph Backend["⚙️ バックエンド層 (Rails 7 - Port 3000)"]
        subgraph Controllers["Controllers"]
            TxCtrl["TransactionsController<br/>メインロジック"]
            CatCtrl["CategoriesController"]
            RuleCtrl["CategoryRulesController"]
            UploadCtrl["UploadHistoriesController"]
        end

        subgraph Services["Services"]
            CsvService["CsvImportService<br/>CSV解析・エンコーディング"]
        end

        subgraph Models["Models"]
            Tx["Transaction<br/>取引記録"]
            Cat["Category<br/>カテゴリ"]
            Rule["CategoryRule<br/>分類ルール"]
            Upload["UploadHistory<br/>アップロード履歴"]
        end

        TxCtrl --> Tx
        CatCtrl --> Cat
        RuleCtrl --> Rule
        UploadCtrl --> Upload
        TxCtrl --> CsvService
        CsvService --> Rule
    end

    subgraph DB["💾 データ層 (SQLite3)"]
        Categories["📊 categories"]
        Transactions["📝 transactions"]
        Rules["🏷️ category_rules"]
        Uploads["📂 upload_histories"]
        Keywords["🔑 category_keywords"]

        Transactions -->|category_id| Categories
        Transactions -->|upload_id| Uploads
        Rules -->|category_id| Categories
        Keywords -->|category_id| Categories
    end

    Frontend -->|HTTP REST JSON| API
    API -->|GET/POST/PATCH/DELETE| Backend
    Backend -->|Active Record ORM| DB

    style Frontend fill:#e1f5ff
    style Backend fill:#fff3e0
    style DB fill:#f3e5f5
    style API fill:#e8f5e9
```

---

## データフロー：CSV インポート

```mermaid
sequenceDiagram
    participant User as ユーザー
    participant Frontend as FileUpload.vue
    participant API as api.js
    participant Backend as TransactionsController
    participant Service as CsvImportService
    participant DB as SQLite3
    participant Response as Response JSON

    User->>Frontend: ファイル選択
    Frontend->>API: @file-uploaded イベント
    API->>Backend: POST /api/v1/transactions/import

    Backend->>Service: new(file, upload_history)

    Note over Service: ① BOM検出・除去
    Note over Service: ② エンコーディング変換<br/>(UTF-8/Shift_JIS)
    Note over Service: ③ 半角カナ→全角カナ
    Note over Service: ④ CSV解析

    loop 各行処理
        Service->>DB: SELECT CategoryRule
        DB-->>Service: ルール取得
        Service->>Service: 自動分類（キーワード一致）
        Service->>DB: CREATE Transaction
    end

    Backend->>DB: CREATE UploadHistory
    Backend-->>Response: { imported_count, errors }
    Response-->>API: JSON レスポンス
    API-->>Frontend: データ受信
    Frontend->>API: api.getMonthlyData()
    API->>Backend: GET /api/v1/transactions/monthly
    Backend-->>API: 月次集計データ
    Frontend->>Frontend: ExpenseChart 再描画

```

---

## カテゴリ自動分類ロジック

```mermaid
graph TD
    Start["Transaction 作成"]
    StoreName["store_name: 楽天ｶｰﾄﾞ"]
    Normalize["正規化<br/>・半角カナ→全角<br/>・小文字化<br/>・記号統一"]
    Query["CategoryRule.by_priority<br/>順に確認"]
    Loop["ルールをループ"]
    Check{"normalized_keyword<br/>in<br/>normalized_store_name?"}
    Found["category_id 取得"]
    NotFound["nil<br/>未分類"]
    End["Transaction 保存"]

    Start --> StoreName
    StoreName --> Normalize
    Normalize --> Query
    Query --> Loop
    Loop --> Check
    Check -->|YES| Found
    Check -->|NO| Loop
    Loop -->|終了| NotFound
    Found --> End
    NotFound --> End

    style Start fill:#c8e6c9
    style End fill:#c8e6c9
    style Found fill:#fff9c4
    style NotFound fill:#ffccbc
```

---

## ページ遷移図

```mermaid
graph LR
    Home["🏠 HomePage<br/>ダッシュボード"]
    Analytics["📊 AnalyticsPage<br/>詳細分析"]
    Rules["🏷️ CategoryRulesPage<br/>ルール管理"]
    Upload["📂 UploadManager<br/>モーダル"]

    Home <-->|navigate| Analytics
    Home <-->|navigate| Rules
    Home -.->|show modal| Upload
    Analytics -.->|show modal| Upload
    Rules -.->|show modal| Upload

    style Home fill:#bbdefb
    style Analytics fill:#ffe0b2
    style Rules fill:#e1bee7
    style Upload fill:#c8e6c9
```

---

## API エンドポイント一覧

```mermaid
graph TB
    API["🔌 API エンドポイント<br/>/api/v1"]

    API --> TX["Transactions"]
    TX --> TXList["GET /transactions<br/>一覧・検索"]
    TX --> TXUpdate["PATCH /transactions/:id<br/>更新"]
    TX --> TXImport["POST /transactions/import<br/>CSV インポート"]
    TX --> TXMonth["GET /transactions/monthly<br/>月次集計"]
    TX --> TXAnalytics["GET /transactions/analytics<br/>詳細分析"]

    API --> CAT["Categories"]
    CAT --> CATList["GET /categories<br/>カテゴリ一覧"]

    API --> RULE["CategoryRules"]
    RULE --> RULEList["GET /category_rules<br/>ルール一覧"]
    RULE --> RULECreate["POST /category_rules<br/>作成"]
    RULE --> RULEUpdate["PATCH /category_rules/:id<br/>更新"]
    RULE --> RULEDelete["DELETE /category_rules/:id<br/>削除"]
    RULE --> RULEBulk["PATCH /category_rules/bulk_update<br/>一括更新"]

    API --> UP["UploadHistories"]
    UP --> UPList["GET /upload_histories<br/>履歴一覧"]
    UP --> UPGet["GET /upload_histories/:id<br/>詳細取得"]
    UP --> UPDelete["DELETE /upload_histories/:id<br/>削除"]

    style API fill:#fff9c4
    style TX fill:#bbdefb
    style CAT fill:#c8e6c9
    style RULE fill:#ffe0b2
    style UP fill:#f8bbd0
```

---

## コンポーネント階層図

```mermaid
graph TD
    App["App.vue<br/>ルート"]

    App --> Header["AppHeader"]
    Header --> Menu["HamburgerMenu"]

    App --> Content["Main Content<br/>動的切り替え"]
    Content --> HP["HomePage"]
    Content --> AP["AnalyticsPage"]
    Content --> CP["CategoryRulesPage"]

    HP --> FU["FileUpload"]
    HP --> EC["ExpenseChart"]
    HP --> SC["SummaryCards"]

    AP --> CT["CategoryTag"]
    AP --> Table["Transaction Table"]

    App --> UM["UploadManager<br/>モーダル"]
    App --> Footer["AppFooter"]

    style App fill:#e3f2fd
    style Header fill:#f5f5f5
    style HP fill:#c8e6c9
    style AP fill:#fff9c4
    style CP fill:#f3e5f5
    style UM fill:#ffccbc
```

---

## データモデルと関連図

```mermaid
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
        int display_order
    }

    TRANSACTIONS {
        int id PK
        int category_id FK
        date transaction_date
        string store_name
        decimal amount
        string payment_method
        int upload_history_id FK
        boolean auto_classified
        text raw_data
    }

    CATEGORY_RULES {
        int id PK
        int category_id FK
        string keyword UK
        int priority
    }

    CATEGORY_KEYWORDS {
        int id PK
        int category_id FK
        string keyword
        int priority
    }

    UPLOAD_HISTORIES {
        int id PK
        string filename
        datetime upload_date
        int imported_count
        string file_hash
        string data_source_type
    }
```

---

## 状態管理フロー（App.vue）

```mermaid
graph TB
    AppState["App.vue<br/>グローバル状態"]

    Page["currentPage<br/>home|analytics<br/>|category-rules"]
    Privacy["isPrivacyMode<br/>true|false"]
    Upload["showUploadManager<br/>true|false"]
    Nav["chartNavigationState<br/>month/date control"]

    AppState --> Page
    AppState --> Privacy
    AppState --> Upload
    AppState --> Nav

    Page -->|props| HP["HomePage"]
    Page -->|props| AP["AnalyticsPage"]
    Page -->|props| CP["CategoryRulesPage"]

    Privacy -->|props| AllPages["全ページ"]
    AllPages -->|emit| AppState

    Nav -->|props| EC["ExpenseChart"]
    EC -->|emit| AppState

    style AppState fill:#fff9c4
    style Page fill:#e1f5ff
    style Privacy fill:#f3e5f5
    style Upload fill:#c8e6c9
    style Nav fill:#ffe0b2
```

---

## テクノロジースタック

```mermaid
graph LR
    Frontend["🎨 フロントエンド"]
    Backend["⚙️ バックエンド"]
    Data["💾 データ"]

    Frontend --> Vue["Vue.js 3<br/>Composition API"]
    Frontend --> Vite["Vite<br/>ビルドツール"]
    Frontend --> Chart["Chart.js<br/>グラフ化"]
    Frontend --> Style["SCSS<br/>Pug"]

    Backend --> Rails["Rails 7<br/>API Mode"]
    Backend --> Puma["Puma<br/>Webサーバー"]
    Backend --> AR["Active Record<br/>ORM"]

    Data --> SQLite["SQLite3<br/>データベース"]
    Data --> CSV["CSV処理<br/>エンコーディング"]

    style Frontend fill:#e1f5ff
    style Backend fill:#fff3e0
    style Data fill:#f3e5f5
```

---

## CSV インポート処理の詳細

```mermaid
graph TD
    Input["入力: CSVファイル"]

    Step1["① ファイル読み込み<br/>バイナリモード"]
    Step2["② BOM検出<br/>UTF-8/UTF-16"]
    Step3["③ エンコーディング判定<br/>UTF-8 or Shift_JIS"]
    Step4["④ エンコーディング変換<br/>NKF使用"]
    Step5["⑤ テキスト正規化<br/>行末統一"]
    Step6["⑥ CSV ヘッダ解析"]

    Step7["⑦ 各行処理<br/>ループ"]
    Parse["データ抽出<br/>date/store/amount"]
    Classify["カテゴリ自動分類<br/>CategoryRule 照合"]
    Create["Transaction 作成"]

    Output["出力: 成功/エラー"]

    Input --> Step1
    Step1 --> Step2
    Step2 --> Step3
    Step3 --> Step4
    Step4 --> Step5
    Step5 --> Step6
    Step6 --> Step7
    Step7 --> Parse
    Parse --> Classify
    Classify --> Create
    Create --> Step7
    Step7 -->|終了| Output

    style Input fill:#c8e6c9
    style Step1 fill:#f5f5f5
    style Step2 fill:#f5f5f5
    style Step3 fill:#f5f5f5
    style Step4 fill:#fff9c4
    style Step5 fill:#fff9c4
    Step6 --> Step7
    Step7 --> Parse
    style Parse fill:#e1f5ff
    style Classify fill:#f3e5f5
    style Create fill:#ffccbc
    style Output fill:#c8e6c9
```

---

## リクエスト-レスポンスパターン

### ① ファイルアップロード

```mermaid
graph LR
    Client["クライアント<br/>FileUpload.vue"]
    Server["サーバー<br/>TransactionsController"]
    DB["データベース<br/>SQLite3"]

    Client -->|POST multipart/form-data<br/>form: { file: File }| Server
    Server -->|Transaction.create| DB
    Server -->|UploadHistory.create| DB
    DB -->|confirmation| Server
    Server -->|JSON Response| Client

    style Client fill:#e1f5ff
    style Server fill:#fff3e0
    style DB fill:#f3e5f5
```

### ② 月次データ取得

```mermaid
graph LR
    Client["クライアント<br/>HomePage.vue"]
    Server["サーバー<br/>TransactionsController"]
    DB["データベース<br/>SQLite3"]

    Client -->|GET /api/v1/transactions/monthly| Server
    Server -->|SQL: GROUP BY category<br/>SUM(amount)| DB
    DB -->|query result| Server
    Server -->|JSON: {<br/>category_totals,<br/>monthly_totals<br/>}| Client

    style Client fill:#e1f5ff
    style Server fill:#fff3e0
    style DB fill:#f3e5f5
```

---

## パフォーマンス・最適化

```mermaid
graph TD
    Frontend["フロントエンド"]

    Frontend --> Opt1["✅ Tree Shaking<br/>Vite"]
    Frontend --> Opt2["✅ SCSS 変数統合<br/>CSSサイズ削減"]
    Frontend --> Opt3["⏳ KeepAlive<br/>コンポーネント状態保持"]

    Backend["バックエンド"]
    Backend --> Opt4["✅ Active Record<br/>includes(:category)"]
    Backend --> Opt5["✅ データベース<br/>インデックス"]
    Backend --> Opt6["✅ SQL グループ化<br/>集計クエリ最適化"]

    style Frontend fill:#e1f5ff
    style Backend fill:#fff3e0
    style Opt1 fill:#c8e6c9
    style Opt2 fill:#c8e6c9
    style Opt3 fill:#fff9c4
    style Opt4 fill:#c8e6c9
    style Opt5 fill:#c8e6c9
    style Opt6 fill:#c8e6c9
```

---

## 今後の拡張計画

```mermaid
graph TB
    Current["現在<br/>SQLite3<br/>同期処理"]

    Phase1["フェーズ1<br/>PostgreSQL 移行<br/>Redis キャッシュ"]
    Phase2["フェーズ2<br/>背景ジョブ化<br/>Sidekiq"]
    Phase3["フェーズ3<br/>マイクロサービス<br/>Kubernetes"]

    Current --> Phase1
    Phase1 --> Phase2
    Phase2 --> Phase3

    style Current fill:#fff9c4
    style Phase1 fill:#ffe0b2
    style Phase2 fill:#ffccbc
    style Phase3 fill:#f3e5f5
```

---

## セキュリティ機能

```mermaid
graph LR
    Security["🔒 セキュリティ"]

    Impl["✅ 実装済み"]
    NotImpl["❌ 未実装"]

    Security --> Impl
    Impl --> SQL["SQL Injection対策<br/>Active Record"]
    Impl --> XSS["XSS対策<br/>JSON Only"]
    Impl --> Params["Strong Parameters<br/>ホワイトリスト"]

    Security --> NotImpl
    NotImpl --> Auth["認証"]
    NotImpl --> AuthZ["認可"]
    NotImpl --> Rate["レート制限"]
    NotImpl --> Enc["暗号化"]

    style Impl fill:#c8e6c9
    style NotImpl fill:#ffccbc
    style Security fill:#fff9c4
```
