# Budget Book - コンポーネント構造図

## コンポーネント階層図

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'fontSize': '16px', 'fontFamily': 'arial'}, 'flowchart': {'htmlLabels': true}}}%%
graph TD
    App["<b>App.vue</b><br/>ルートコンポーネント<br/>━━━━━━━━━━━<br/>状態:<br/>• currentPage<br/>• isPrivacyMode<br/>• showUploadManager<br/>• chartNavigationState"]

    Header["<b>AppHeader.vue</b><br/>ナビゲーション"]
    Menu["<b>HamburgerMenu.vue</b><br/>メニュー"]

    Main["Main Content<br/>動的切り替え"]
    HomePage["<b>HomePage.vue</b><br/>ダッシュボード"]
    Analytics["<b>AnalyticsPage.vue</b><br/>詳細分析"]
    Rules["<b>CategoryRulesPage.vue</b><br/>ルール管理"]

    FileUp["<b>FileUpload.vue</b><br/>CSV選択<br/>━━━━━━━━━━<br/>Props: loading<br/>Emits: file-uploaded<br/>folder-uploaded"]
    Chart["<b>ExpenseChart.vue</b><br/>グラフ表示<br/>━━━━━━━━━━<br/>Props: data, isPrivacyMode<br/>Emits: navigation-state"]
    Summary["<b>SummaryCards.vue</b><br/>統計カード<br/>━━━━━━━━━━<br/>Props: summary,<br/>isPrivacyMode"]

    CategoryTag["<b>CategoryTag.vue</b><br/>カテゴリタグ<br/>━━━━━━━━━━<br/>Props: category<br/>Emits: change-category"]
    TransTable["Transaction Table<br/>トランザクション表"]

    UploadMgr["<b>UploadManager.vue</b><br/>アップロード管理<br/>━━━━━━━━━━<br/>Emits: close<br/>data-updated"]

    Footer["<b>AppFooter.vue</b><br/>フッター"]

    App --> Header
    Header --> Menu
    App --> Main
    Main --> HomePage
    Main --> Analytics
    Main --> Rules
    HomePage --> FileUp
    HomePage --> Chart
    HomePage --> Summary
    Analytics --> CategoryTag
    Analytics --> TransTable
    App --> UploadMgr
    App --> Footer

    style App fill:#bbdefb,stroke:#01579b,stroke-width:3px,color:#000
    style Header fill:#c8e6c9,stroke:#1b5e20,stroke-width:2px
    style Menu fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    style Main fill:#f0f4c3,stroke:#827717,stroke-width:2px
    style HomePage fill:#81d4fa,stroke:#01579b,stroke-width:2px
    style Analytics fill:#ffcc80,stroke:#e65100,stroke-width:2px
    style Rules fill:#ce93d8,stroke:#4a148c,stroke-width:2px
    style FileUp fill:#c8e6c9,stroke:#1b5e20,stroke-width:1px
    style Chart fill:#b3e5fc,stroke:#01579b,stroke-width:1px
    style Summary fill:#b3e5fc,stroke:#01579b,stroke-width:1px
    style CategoryTag fill:#ffe0b2,stroke:#e65100,stroke-width:1px
    style TransTable fill:#ffe0b2,stroke:#e65100,stroke-width:1px
    style UploadMgr fill:#f8bbd0,stroke:#880e4f,stroke-width:2px
    style Footer fill:#e0e0e0,stroke:#424242,stroke-width:1px
```

## Props と Emits の流れ

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'fontSize': '16px', 'fontFamily': 'arial'}, 'flowchart': {'htmlLabels': true}}}%%
graph TB
    subgraph AppState["App.vue<br/>グローバル状態"]
        Page["currentPage"]
        Privacy["isPrivacyMode"]
        Upload["showUploadManager"]
        Nav["chartNavigationState"]
    end

    subgraph PropsFlow["Props Flow<br/>親 → 子"]
        P1["HomePage<br/>←<br/>isPrivacyMode<br/>chartNavigationState"]
        P2["AnalyticsPage<br/>←<br/>isPrivacyMode<br/>chartNavigationState"]
        P3["Header<br/>←<br/>currentPage<br/>isPrivacyMode"]
        P4["Chart<br/>←<br/>data<br/>isPrivacyMode"]
    end

    subgraph EmitsFlow["Emits Flow<br/>子 → 親"]
        E1["HomePage<br/>→<br/>@navigate<br/>@chart-navigation"]
        E2["Header<br/>→<br/>@navigate<br/>@toggle-privacy<br/>@show-upload"]
        E3["Menu<br/>→<br/>@navigate<br/>@toggle-privacy"]
        E4["Chart<br/>→<br/>@navigation-state"]
    end

    AppState --> PropsFlow
    AppState --> EmitsFlow

    P1 & P2 & P3 & P4 -.->|双方向更新| AppState
    E1 & E2 & E3 & E4 -.->|イベント通知| AppState

    style AppState fill:#fff9c4,stroke:#f57f17,stroke-width:3px
    style PropsFlow fill:#c8e6c9,stroke:#1b5e20,stroke-width:2px
    style EmitsFlow fill:#ffccbc,stroke:#d84315,stroke-width:2px
```

## ページコンポーネント詳細

### HomePage

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'fontSize': '14px', 'fontFamily': 'arial'}, 'flowchart': {'htmlLabels': true}}}%%
graph TD
    Home["<b>HomePage.vue</b><br/>┏━━━━━━━━━━━━━━━━┓<br/>┃ Props:           ┃<br/>┃ • isPrivacyMode  ┃<br/>┃ • chartNavState  ┃<br/>┗━━━━━━━━━━━━━━━━┛<br/><br/>┏━━━━━━━━━━━━━━━━┓<br/>┃ State:           ┃<br/>┃ • loading        ┃<br/>┃ • chartData      ┃<br/>┃ • summaryData    ┃<br/>┗━━━━━━━━━━━━━━━━┛"]

    Upload["<b>FileUpload.vue</b><br/>━━━━━━━<br/>ファイル選択<br/>フォルダ選択<br/>プログレス表示"]

    Chart["<b>ExpenseChart.vue</b><br/>━━━━━━━<br/>月次グラフ<br/>カテゴリ円グラフ<br/>ナビゲーション"]

    Summary["<b>SummaryCards.vue</b><br/>━━━━━━━<br/>今月の支出<br/>月平均<br/>最大月支出<br/>データ件数"]

    Home --> Upload
    Home --> Chart
    Home --> Summary

    Upload -->|@file-uploaded| Home
    Upload -->|@folder-uploaded| Home
    Chart -->|@navigation-state| Home

    style Home fill:#81d4fa,stroke:#01579b,stroke-width:3px
    style Upload fill:#c8e6c9,stroke:#1b5e20,stroke-width:2px
    style Chart fill:#b3e5fc,stroke:#01579b,stroke-width:2px
    style Summary fill:#b3e5fc,stroke:#01579b,stroke-width:2px
```

### AnalyticsPage

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'fontSize': '14px', 'fontFamily': 'arial'}, 'flowchart': {'htmlLabels': true}}}%%
graph TD
    Analytics["<b>AnalyticsPage.vue</b><br/>┏━━━━━━━━━━━━┓<br/>┃ Props:         ┃<br/>┃ • chartNavState┃<br/>┃ • isPrivacyMode┃<br/>┗━━━━━━━━━━━━┛<br/><br/>┏━━━━━━━━━━━━┓<br/>┃ Features:      ┃<br/>┃ • 日次トレンド ┃<br/>┃ • 店舗TOP10   ┃<br/>┃ • 統計表示     ┃<br/>┗━━━━━━━━━━━━┛"]

    DailyChart["Day Chart<br/>日次トレンド"]
    PieChart["Pie Chart<br/>カテゴリ分析"]
    BarChart["Bar Chart<br/>店舗TOP10"]
    Stats["Statistics<br/>統計情報"]
    TransTable["Transaction Table<br/>━━━━━━━━━━<br/>CategoryTag で<br/>カテゴリ変更可能"]

    Analytics --> DailyChart
    Analytics --> PieChart
    Analytics --> BarChart
    Analytics --> Stats
    Analytics --> TransTable

    TransTable --> CategoryTag["CategoryTag<br/>━━━━<br/>Props:<br/>• category<br/>Emits:<br/>• @change"]

    CategoryTag -->|@change-category| TransTable

    style Analytics fill:#ffcc80,stroke:#e65100,stroke-width:3px
    style DailyChart fill:#ffe0b2,stroke:#e65100,stroke-width:2px
    style PieChart fill:#ffe0b2,stroke:#e65100,stroke-width:2px
    style BarChart fill:#ffe0b2,stroke:#e65100,stroke-width:2px
    style Stats fill:#ffe0b2,stroke:#e65100,stroke-width:2px
    style TransTable fill:#ffb74d,stroke:#e65100,stroke-width:2px
    style CategoryTag fill:#ffe0b2,stroke:#e65100,stroke-width:1px
```

### CategoryRulesPage

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'fontSize': '14px', 'fontFamily': 'arial'}, 'flowchart': {'htmlLabels': true}}}%%
graph TD
    Rules["<b>CategoryRulesPage.vue</b><br/>━━━━━━━━━━<br/>ルール管理"]

    RuleList["Rules List<br/>━━━━━━<br/>• ルール一覧<br/>• 優先度表示<br/>• 削除ボタン"]

    RuleForm["Add/Edit Form<br/>━━━━━━<br/>• keyword 入力<br/>• category 選択<br/>• 優先度設定"]

    Actions["Actions<br/>━━━━━━<br/>• Create<br/>• Update<br/>• Delete<br/>• Bulk Update"]

    Rules --> RuleList
    Rules --> RuleForm
    Rules --> Actions

    RuleList -->|click edit| RuleForm
    RuleForm -->|submit| Actions

    style Rules fill:#ce93d8,stroke:#4a148c,stroke-width:3px
    style RuleList fill:#e1bee7,stroke:#4a148c,stroke-width:2px
    style RuleForm fill:#e1bee7,stroke:#4a148c,stroke-width:2px
    style Actions fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
```

## API通信パターン

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'fontSize': '16px', 'fontFamily': 'arial'}, 'flowchart': {'htmlLabels': true}}}%%
graph LR
    subgraph FrontendComps["フロントエンド<br/>コンポーネント"]
        FU["FileUpload"]
        HP["HomePage"]
        AP["AnalyticsPage"]
        CP["CategoryRulesPage"]
    end

    subgraph ApiService["api.js<br/>シングルトン"]
        Upload["uploadCsv()"]
        GetMonth["getMonthlyData()"]
        GetAnalytics["getAnalyticsData()"]
        GetRules["getCategoryRules()"]
        UpdateTx["updateTransaction()"]
        CreateRule["createCategoryRule()"]
        DeleteRule["deleteCategoryRule()"]
    end

    subgraph Controllers["Rails Controllers"]
        TxCtrl["TransactionsController"]
        RuleCtrl["CategoryRulesController"]
    end

    FU -->|emit file| HP
    HP -->|call| Upload
    HP -->|call| GetMonth

    AP -->|call| GetAnalytics
    AP -->|call| UpdateTx

    CP -->|call| GetRules
    CP -->|call| CreateRule
    CP -->|call| DeleteRule

    Upload --> TxCtrl
    GetMonth --> TxCtrl
    GetAnalytics --> TxCtrl
    UpdateTx --> TxCtrl

    GetRules --> RuleCtrl
    CreateRule --> RuleCtrl
    DeleteRule --> RuleCtrl

    style FrontendComps fill:#81d4fa,stroke:#01579b,stroke-width:2px
    style ApiService fill:#c8e6c9,stroke:#1b5e20,stroke-width:2px
    style Controllers fill:#ffb74d,stroke:#e65100,stroke-width:2px
```
