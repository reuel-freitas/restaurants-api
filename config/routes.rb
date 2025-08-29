Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  mount MissionControl::Jobs::Engine, at: "/jobs"

  get "up" => "health#show", as: :rails_health_check
  get "coverage" => "health#coverage", as: :test_coverage

  resources :restaurants, only: [ :index, :show ] do
    resources :menus, only: [ :index, :show ] do
      resources :menu_items, only: [ :index, :show ]
    end
    resources :menu_items, only: [ :index, :show ]
  end

  resources :menus, only: [ :index, :show ]
  resources :menu_items, only: [ :index, :show ]

  post "/import", to: "import#create"
  post "/import/upload", to: "import#upload"
  get "/import/status/:job_id", to: "import#status"

  root "health#show"
end
