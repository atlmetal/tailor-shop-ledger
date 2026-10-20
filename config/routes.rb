Rails.application.routes.draw do
  resource :session, only: %i[ new create destroy ]
  resource :account, only: %i[ show update ]

  resources :services, only: %i[ index new create edit update ] do
    resource :activation, only: %i[ create destroy ]
  end
  resources :fixed_costs, only: %i[ index create update ]
  resource :work_days, only: :update

  resources :jobs, only: %i[ new create edit update destroy ]
  # An order's jobs and payments live under it, so the order they belong to comes from the URL.
  resources :orders, only: %i[ new create show edit update destroy ] do
    resources :jobs, only: %i[ new create edit update destroy ], module: :orders
    resources :payments, only: %i[ new create edit update destroy ], module: :orders
  end
  # And an advance's jobs and top-ups, under it.
  resources :advances, only: %i[ new create show edit update destroy ] do
    resources :jobs, only: %i[ new create edit update destroy ], module: :advances
    resources :top_ups, only: %i[ new create edit update destroy ], module: :advances
  end
  # Expenses and other income are both entries: one controller, told apart by the kind each route gives.
  resources :expenses, controller: "entries", only: %i[ new create edit update destroy ], defaults: { kind: "expense" }
  resources :incomes, controller: "entries", only: %i[ new create edit update destroy ], defaults: { kind: "income" }

  # The current month, or the period of a kind that holds a date, named by its first day: /reports/week/2026-10-12.
  get "reports" => "reports#show"
  get "reports/:kind/:date" => "reports#show", as: :report, constraints: { kind: /day|week|month|semester|year/, date: /\d{4}-\d{2}-\d{2}/ }

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "today#show"
end
