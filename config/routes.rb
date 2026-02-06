Rails.application.routes.draw do
  # Root
  root "events#index"

  # Static pages
  get "about", to: "pages#about"

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
  resources :users, only: [ :index, :show, :destroy ] do
    member do
      post :toggle_approved_organiser
    end
  end

  # Admin - Events management
  namespace :admin do
    get "events/pending", to: "events#pending", as: :pending_events
    post "events/:id/approve", to: "events#approve", as: :approve_event
    delete "events/:id/reject", to: "events#reject", as: :reject_event
  end

  # Email subscriptions (weekly digest)
  get  "subscribe", to: "email_subscriptions#new", as: :new_email_subscription
  post "subscribe", to: "email_subscriptions#create", as: :email_subscriptions
  get  "unsubscribe/:token", to: "email_subscriptions#destroy", as: :unsubscribe

  # Health check for deployment
  get "up" => "rails/health#show", as: :rails_health_check

  # Filtered event views (at the end to avoid conflicts with other routes)
  # URLs like /auckland or /wellington/Wellington%20CBD
  get ":region/:city", to: "events#index", as: :filtered_events_city,
      constraints: { region: /[a-z_]+/, city: /[a-z_]+/ }
  get ":region", to: "events#index", as: :filtered_events_region,
      constraints: { region: /[a-z_]+/ }
end
