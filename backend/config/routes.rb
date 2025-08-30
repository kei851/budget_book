Rails.application.routes.draw do
  # API namespace
  namespace :api do
    namespace :v1 do
      # カテゴリルールAPI
      resources :category_rules, only: [:index, :create, :update, :destroy] do
        collection do
          patch :bulk_update  # 一括更新
        end
      end
      # カテゴリAPI
      resources :categories, only: [:index]
      
      # 取引データAPI
      resources :transactions, only: [:index, :update] do
        collection do
          post :import        # CSV一括インポート
          get :monthly        # 月次集計データ
          get :analytics      # 分析データ
        end
      end
      
      # アップロード履歴API
      resources :upload_histories, only: [:index, :show, :destroy]
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
