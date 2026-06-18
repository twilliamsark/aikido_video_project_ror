Rails.application.routes.draw do
  resource :session, only: %i[ new create destroy ]
  resources :passwords, param: :token, only: %i[ new create edit update ]

  scope module: :public do
    resources :videos, only: %i[ index show ]
    get "watch/:token", to: "video_shares#show", as: :public_video_share
  end

  namespace :teachers, path: "teacher", as: "teacher" do
    root "dashboard#show"
    resources :videos do
      collection do
        post :import
        get :export
      end

      resource :share, only: %i[ create destroy ], controller: "video_shares"
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "public/videos#index"
end
