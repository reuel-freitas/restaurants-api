Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  mount MissionControl::Jobs::Engine, at: "/jobs"
  get "up" => "rails/health#show", as: :rails_health_check
  # API routes for Level 2
  resources :restaurants, only: [ :index, :show ] do
    resources :menus, only: [ :index, :show ] do
      resources :menu_items, only: [ :index, :show ]
    end
    resources :menu_items, only: [ :index, :show ]
  end

  # Keep global endpoints for backward compatibility
  resources :menus, only: [ :index, :show ]
  resources :menu_items, only: [ :index, :show ]

  # Import routes for Level 3
  post "/import", to: "import#create"
  post "/import/upload", to: "import#upload"
  get "/import/status/:job_id", to: "import#status"

  # Defines the root path route ("/")
  # root "posts#index"
end
