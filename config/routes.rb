Rails.application.routes.draw do
  resource :session, only: %i[ new create destroy ]
  resource :account, only: %i[ show update ]

  resources :services, only: %i[ index new create edit update ] do
    resource :activation, only: %i[ create destroy ]
  end
  resources :fixed_costs, only: %i[ index create update ]
  resource :work_days, only: :update

  resources :jobs, only: %i[ new create edit update destroy ]

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "today#show"
end
