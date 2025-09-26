# Railsアプリケーションのルーティング設定を定義するブロックを開始する
Rails.application.routes.draw do
  # APIエンドポイントを名前空間で整理し、URLに/apiプレフィックスを追加する
  namespace :api do
    # APIのバージョン1を定義し、URLに/v1プレフィックスを追加する（将来のバージョン管理のため）
    namespace :v1 do
      # カテゴリルール管理APIのリソースルーティングを定義する
      # only: で指定したアクション（index, create, update, destroy）のみを有効にする
      resources :category_rules, only: [:index, :create, :update, :destroy] do
        # collectionブロック：個別リソースではなくコレクション全体に対するカスタムアクションを定義する
        collection do
          # PATCH /api/v1/category_rules/bulk_update - 複数のカテゴリルールを一度に更新するエンドポイント
          patch :bulk_update  # 一括更新機能のルート
        end
      end
      # カテゴリ一覧取得APIのリソースルーティングを定義する
      # only: [:index]でGET /api/v1/categoriesのみを有効にする
      resources :categories, only: [:index]
      
      # 取引データ管理APIのリソースルーティングを定義する
      # only: で指定したアクション（index, update）のみを有効にする
      resources :transactions, only: [:index, :update] do
        # collectionブロック：取引データ全体に対するカスタムアクションを定義する
        collection do
          # POST /api/v1/transactions/import - CSVファイルから取引データを一括インポートするエンドポイント
          post :import        # CSV一括インポート機能のルート
          # GET /api/v1/transactions/monthly - 月次集計データを取得するエンドポイント
          get :monthly        # 月次集計データ取得機能のルート
          # GET /api/v1/transactions/analytics - 詳細な分析データを取得するエンドポイント
          get :analytics      # 分析データ取得機能のルート
        end
      end
      
      # アップロード履歴管理APIのリソースルーティングを定義する
      # only: で指定したアクション（index, show, destroy）のみを有効にする
      resources :upload_histories, only: [:index, :show, :destroy]
    end
  end

  # アプリケーションのヘルスチェック用エンドポイントを定義する
  # GET /up でRailsの組み込みヘルスチェック機能にアクセスし、as: でルート名を設定する
  get "up" => "rails/health#show", as: :rails_health_check
# ルーティング設定ブロックの終了
end
