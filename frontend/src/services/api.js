// バックエンドRails APIとの通信を一元管理するAPIサービスクラス定義ファイル
// ローカル開発環境用のバックエンドAPIサーバーのベースURLを定数で定義
const API_BASE_URL = 'http://localhost:3000/api/v1'

// フロントエンドからバックエンドへの全APIリクエストを集約するサービスクラス
class ApiService {
  // コンストラクタ：インスタンス作成時にベースURLを初期化
  constructor() {
    // インスタンスのbaseURLプロパティに定数のAPI_BASE_URLを設定
    this.baseURL = API_BASE_URL
  }

  // CSVファイルをサーバーにアップロードして取引データをインポートする非同期メソッド
  async uploadCsv(file, clearExisting = false) {
    // HTML5のFormDataオブジェクトを作成してファイルアップロード用のデータコンテナを準備
    const formData = new FormData()
    // CSVファイルオブジェクトを'csv_file'キーでFormDataに追加（RailsのStrong Parametersに対応）
    formData.append('csv_file', file)
    // 既存データ消去フラグを文字列化してFormDataに追加（booleanを直接送信不可）
    formData.append('clear_existing', clearExisting.toString())

    // バックエンドのtransactions/importエンドポイントにファイルアップロード用POSTリクエストを非同期送信
    const response = await fetch(`${this.baseURL}/transactions/import`, {
      // HTTPメソッドをPOSTに設定（ファイルアップロードは通常POST）
      method: 'POST',
      // FormDataオブジェクトをリクエストボディに設定（Content-Typeは自動設定される）
      body: formData,
      // レスポンスのAcceptヘッダーでJSON形式を期待することを明示
      headers: {
        'Accept': 'application/json'
      }
    })

    // HTTPレスポンスのステータスコードが成功範囲（2xx）でない場合のエラーハンドリング
    if (!response.ok) {
      // サーバーからのエラーレスポンスをJSON形式で非同期取得
      const error = await response.json()
      // サーバーからのエラーメッセージがあればそれを、なければデフォルトメッセージでJavaScriptのErrorをthrow
      throw new Error(error.error || 'アップロードに失敗しました')
    }

    // アップロード成功時はサーバーからのレスポンスデータをJSON形式で非同期取得して返す
    return await response.json()
  }

  // 取引データ一覧を条件パラメータ付きで取得する非同期メソッド
  async getTransactions(params = {}) {
    // ブラウザーAPIのURLSearchParamsを使用してURLクエリパラメータを構築
    const queryParams = new URLSearchParams()

    // パラメータオブジェクトの各キーに対してループ処理を実行
    Object.keys(params).forEach(key => {
      // パラメータ値がnullまたはundefinedでない場合のみクエリに追加（空値の送信を防止）
      if (params[key] !== null && params[key] !== undefined) {
        // キーと値のペアをURLSearchParamsに追加（自動でURLエンコードされる）
        queryParams.append(key, params[key])
      }
    })

    // transactionsエンドポイントに組み立てたクエリパラメータ付きGETリクエストを非同期送信
    const response = await fetch(`${this.baseURL}/transactions?${queryParams}`)

    // HTTPレスポンスのステータスコードが成功範囲（2xx）でない場合はエラーをthrow
    if (!response.ok) {
      throw new Error('データの取得に失敗しました')
    }

    // データ取得成功時はレスポンスボディをJSON形式で非同期パースして返す
    return await response.json()
  }

  // 指定年月の取引データを集計して月次サマリーを取得する非同期メソッド
  async getMonthlyData(year = null, month = null) {
    // URLSearchParamsオブジェクトを作成して月次データ取得用のクエリパラメータを管理
    const params = new URLSearchParams()
    // 年パラメータが指定されている場合（truthy判定）はクエリパラメータに追加
    if (year) params.append('year', year)
    // 月パラメータが指定されている場合（truthy判定）はクエリパラメータに追加
    if (month) params.append('month', month)

    // transactions/monthlyエンドポイントに年月パラメータ付きGETリクエストを非同期送信
    const response = await fetch(`${this.baseURL}/transactions/monthly?${params}`)

    // HTTPレスポンスのステータスコードが成功範囲（2xx）でない場合はエラーをthrow
    if (!response.ok) {
      throw new Error('月次データの取得に失敗しました')
    }

    // 月次集計データ取得成功時はレスポンスをJSON形式で非同期パースして返す
    return await response.json()
  }

  // 指定期間の取引データを分析して統計情報やグラフ用データを取得する非同期メソッド
  async getAnalyticsData(startDate = null, endDate = null) {
    // URLSearchParamsオブジェクトを作成して分析期間指定用のクエリパラメータを管理
    const params = new URLSearchParams()
    // 開始日が指定されている場合（truthy判定）はクエリパラメータに追加
    if (startDate) params.append('start_date', startDate)
    // 終了日が指定されている場合（truthy判定）はクエリパラメータに追加
    if (endDate) params.append('end_date', endDate)

    // transactions/analyticsエンドポイントに期間パラメータ付きGETリクエストを非同期送信
    const response = await fetch(`${this.baseURL}/transactions/analytics?${params}`)

    // HTTPレスポンスのステータスコードが成功範囲（2xx）でない場合はエラーをthrow
    if (!response.ok) {
      throw new Error('分析データの取得に失敗しました')
    }

    // 分析データ取得成功時は統計情報をJSON形式で非同期パースして返す
    return await response.json()
  }

  // アプリケーションで使用する全カテゴリマスタデータを取得する非同期メソッド
  async getCategories() {
    // categoriesエンドポイントにパラメータなしのGETリクエストを非同期送信
    const response = await fetch(`${this.baseURL}/categories`)

    // HTTPレスポンスのステータスコードが成功範囲（2xx）でない場合はエラーをthrow
    if (!response.ok) {
      throw new Error('カテゴリデータの取得に失敗しました')
    }

    // カテゴリデータ取得成功時はカテゴリ一覧をJSON形式で非同期パースして返す
    return await response.json()
  }

  // 指定IDの取引データを部分更新する非同期メソッド
  async updateTransaction(id, data) {
    // 特定の取引データのRESTエンドポイントにPATCHリクエストを非同期送信
    const response = await fetch(`${this.baseURL}/transactions/${id}`, {
      // HTTPメソッドをPATCHに設定（部分更新のRESTfulパターン）
      method: 'PATCH',
      // リクエストヘッダーでJSON形式のコンテントとレスポンス形式を指定
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      // 更新データをRailsのStrong Parametersに合わせてtransactionキーでネストしてJSON化
      body: JSON.stringify({ transaction: data })
    })

    // HTTPレスポンスのステータスコードが成功範囲（2xx）でない場合のエラーハンドリング
    if (!response.ok) {
      // サーバーからのエラーレスポンスをJSON形式で非同期取得
      const error = await response.json()
      // Railsのバリデーションエラー配列をカンマ区切りで結合するかデフォルトメッセージでErrorをthrow
      throw new Error(error.errors?.join(', ') || '更新に失敗しました')
    }

    // 更新成功時は更新後の取引データをJSON形式で非同期パースして返す
    return await response.json()
  }

  // CSVアップロード履歴の一覧データを取得する非同期メソッド
  async getUploadHistories() {
    // upload_historiesエンドポイントにパラメータなしのGETリクエストを非同期送信
    const response = await fetch(`${this.baseURL}/upload_histories`)

    // HTTPレスポンスのステータスコードが成功範囲（2xx）でない場合はエラーをthrow
    if (!response.ok) {
      throw new Error('履歴データの取得に失敗しました')
    }

    // アップロード履歴一覧取得成功時は履歴データをJSON形式で非同期パースして返す
    return await response.json()
  }

  // 指定IDのCSVアップロード履歴の詳細情報を取得する非同期メソッド
  async getUploadHistory(id) {
    // 特定のアップロード履歴のRESTエンドポイントにGETリクエストを非同期送信
    const response = await fetch(`${this.baseURL}/upload_histories/${id}`)

    // HTTPレスポンスのステータスコードが成功範囲（2xx）でない場合はエラーをthrow
    if (!response.ok) {
      throw new Error('履歴データの取得に失敗しました')
    }

    // アップロード履歴詳細取得成功時は詳細データをJSON形式で非同期パースして返す
    return await response.json()
  }

  // 指定IDのアップロード履歴とその関連取引データを継枝削除する非同期メソッド
  async deleteUploadHistory(id) {
    // 特定のアップロード履歴のRESTエンドポイントにDELETEリクエストを非同期送信
    const response = await fetch(`${this.baseURL}/upload_histories/${id}`, {
      // HTTPメソッドをDELETEに設定（リソース削除のRESTfulパターン）
      method: 'DELETE',
      // レスポンスのAcceptヘッダーでJSON形式を期待することを明示
      headers: {
        'Accept': 'application/json'
      }
    })

    // HTTPレスポンスのステータスコードが成功範囲（2xx）でない場合のエラーハンドリング
    if (!response.ok) {
      // サーバーからのエラーレスポンスをJSON形式で非同期取得
      const error = await response.json()
      // サーバーからのエラーメッセージがあればそれを、なければデフォルトメッセージでJavaScriptのErrorをthrow
      throw new Error(error.error || '削除に失敗しました')
    }

    // アップロード履歴削除成功時は削除結果のメッセージをJSON形式で非同期パースして返す
    return await response.json()
  }

  // 取引データの自動カテゴリ分類ルール一覧を取得する非同期メソッド
  async getCategoryRules() {
    // category_rulesエンドポイントにパラメータなしのGETリクエストを非同期送信
    const response = await fetch(`${this.baseURL}/category_rules`)

    // HTTPレスポンスのステータスコードが成功範囲（2xx）でない場合はエラーをthrow
    if (!response.ok) {
      throw new Error('カテゴリルールの取得に失敗しました')
    }

    // カテゴリルール一覧取得成功時はルールデータをJSON形式で非同期パースして返す
    return await response.json()
  }

  // 新しいカテゴリ自動分類ルールをサーバーに作成する非同期メソッド
  async createCategoryRule(ruleData) {
    // category_rulesエンドポイントにルール作成用POSTリクエストを非同期送信
    const response = await fetch(`${this.baseURL}/category_rules`, {
      // HTTPメソッドをPOSTに設定（新規リソース作成のRESTfulパターン）
      method: 'POST',
      // リクエストヘッダーでJSON形式のコンテントとレスポンス形式を指定
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      // ルールデータをRailsのStrong Parametersに合わせてcategory_ruleキーでネストしてJSON化
      body: JSON.stringify({ category_rule: ruleData })
    })

    // HTTPレスポンスのステータスコードが成功範囲（2xx）でない場合のエラーハンドリング
    if (!response.ok) {
      // サーバーからのエラーレスポンスをJSON形式で非同期取得
      const error = await response.json()
      // Railsのバリデーションエラー配列をカンマ区切りで結合するかデフォルトメッセージでErrorをthrow
      throw new Error(error.errors?.join(', ') || 'ルールの作成に失敗しました')
    }

    // ルール作成成功時は作成されたルールデータをJSON形式で非同期パースして返す
    return await response.json()
  }

  // 指定IDのカテゴリ自動分類ルールを部分更新する非同期メソッド
  async updateCategoryRule(id, ruleData) {
    // 特定のカテゴリルールのRESTエンドポイントに更新用PATCHリクエストを非同期送信
    const response = await fetch(`${this.baseURL}/category_rules/${id}`, {
      // HTTPメソッドをPATCHに設定（部分更新のRESTfulパターン）
      method: 'PATCH',
      // リクエストヘッダーでJSON形式のコンテントとレスポンス形式を指定
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      // 更新ルールデータをRailsのStrong Parametersに合わせてcategory_ruleキーでネストしてJSON化
      body: JSON.stringify({ category_rule: ruleData })
    })

    // HTTPレスポンスのステータスコードが成功範囲（2xx）でない場合のエラーハンドリング
    if (!response.ok) {
      // サーバーからのエラーレスポンスをJSON形式で非同期取得
      const error = await response.json()
      // Railsのバリデーションエラー配列をカンマ区切りで結合するかデフォルトメッセージでErrorをthrow
      throw new Error(error.errors?.join(', ') || 'ルールの更新に失敗しました')
    }

    // ルール更新成功時は更新後のルールデータをJSON形式で非同期パースして返す
    return await response.json()
  }

  // 指定IDのカテゴリ自動分類ルールをサーバーから削除する非同期メソッド
  async deleteCategoryRule(id) {
    // 特定のカテゴリルールのRESTエンドポイントに削除用DELETEリクエストを非同期送信
    const response = await fetch(`${this.baseURL}/category_rules/${id}`, {
      // HTTPメソッドをDELETEに設定（リソース削除のRESTfulパターン）
      method: 'DELETE',
      // レスポンスのAcceptヘッダーでJSON形式を期待することを明示
      headers: {
        'Accept': 'application/json'
      }
    })

    // HTTPレスポンスのステータスコードが成功範囲（2xx）でない場合のエラーハンドリング
    if (!response.ok) {
      // サーバーからのエラーレスポンスをJSON形式で非同期取得
      const error = await response.json()
      // サーバーからのエラーメッセージがあればそれを、なければデフォルトメッセージでJavaScriptのErrorをthrow
      throw new Error(error.error || 'ルールの削除に失敗しました')
    }

    // ルール削除成功時は削除完了を示すbooleanのtrueを返す（JSONレスポンスではない）
    return true
  }

  // 指定キーワードを含む全取引データのカテゴリを一括で新しいカテゴリに変更する非同期メソッド
  async bulkUpdateCategory(keyword, newCategoryId) {
    // category_rules/bulk_update特別エンドポイントに一括更新用PATCHリクエストを非同期送信
    const response = await fetch(`${this.baseURL}/category_rules/bulk_update`, {
      // HTTPメソッドをPATCHに設定（一括更新のためのカスタムエンドポイント）
      method: 'PATCH',
      // リクエストヘッダーでJSON形式のコンテントとレスポンス形式を指定
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      // 検索キーワードと新しいカテゴリIDをフラットな構造でJSON化（Strong Parametersのネストなし）
      body: JSON.stringify({
        keyword: keyword,
        new_category_id: newCategoryId
      })
    })

    // HTTPレスポンスのステータスコードが成功範囲（2xx）でない場合のエラーハンドリング
    if (!response.ok) {
      // サーバーからのエラーレスポンスをJSON形式で非同期取得
      const error = await response.json()
      // サーバーからのエラーメッセージがあればそれを、なければデフォルトメッセージでJavaScriptのErrorをthrow
      throw new Error(error.error || '一括更新に失敗しました')
    }

    // 一括更新成功時は更新結果の統計情報をJSON形式で非同期パースして返す
    return await response.json()
  }
}

// ApiServiceクラスのインスタンスを作成してexportする（シングルトンパターンでアプリ全体で共有）
export default new ApiService()