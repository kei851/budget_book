# このファイルを変更したら、必ずサーバーを再起動してください
# Be sure to restart your server when you modify this file.

# フロントエンドアプリからAPIが呼び出された際のCORS問題を回避します
# Avoid CORS issues when API is called from the frontend app.
# クロスオリジンのAjaxリクエストを受け入れるために、CORS（Cross-Origin Resource Sharing）を処理します
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# 詳細はこちら: https://github.com/cyu/rack-cors
# Read more: https://github.com/cyu/rack-cors

# Railsアプリケーションのミドルウェアスタックの最初（0番目）にRack::Corsを挿入します
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  # CORS許可設定のブロック開始
  allow do
    # 許可するオリジン（アクセス元）のリスト - 開発環境用の各種ポート番号を指定
    # localhost:3000 - Rails標準ポート
    # localhost:3002 - Vue.js開発サーバー（このプロジェクトで使用）
    # localhost:3003 - 予備ポート
    # localhost:5173 - Vite標準ポート
    origins "http://localhost:3000", "http://localhost:3002", "http://localhost:3003", "http://localhost:5173"

    # すべてのリソース（"*"）に対するCORS設定
    resource "*",
      # すべてのHTTPヘッダーを許可
      headers: :any,
      # 許可するHTTPメソッドのリスト（GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD）
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ]
  end
end
