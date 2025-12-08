Rails.application.routes.draw do
  # Root
  root "events#index"

  # Authentication (email/password)
  get  "login", to: "sessions#new", as: :new_session
  post "login", to: "sessions#create", as: :session
  delete "logout", to: "sessions#destroy"

  # Registration
  get  "signup", to: "registrations#new", as: :new_registration
  post "signup", to: "registrations#create", as: :registration

  # OAuth callbacks
  get  "/auth/google_oauth2/callback", to: "oauth_callbacks#google_oauth2"
  get  "/auth/failure", to: "oauth_callbacks#failure"

  # Password resets (from Rails 8 generator)
  resources :passwords, param: :token

  # Events
  resources :events do
    collection do
      get :past
      get :my_events
    end
    member do
      get :ical
    end
  end

  # Admin - Users management
  resources :users, only: [:index, :destroy]

  # Health check for deployment
  get "up" => "rails/health#show", as: :rails_health_check
end
