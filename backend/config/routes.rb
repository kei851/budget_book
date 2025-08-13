Rails.application.routes.draw do
  # API namespace
  namespace :api do
    namespace :v1 do
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
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
