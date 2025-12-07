# NZ Tech Events - Step-by-Step Implementation Plan

A detailed, sequential implementation guide optimized for AI agents. Each step is atomic, testable, and builds on the previous step.

---

## Architecture Overview

### No-Build Stack (Zero Node.js)
- **Rails 8.0** with Propshaft (asset pipeline)
- **Importmaps** for JavaScript (no bundling)
- **Pico CSS** via CDN (classless CSS, no build step)
- **SQLite** for everything (database, cache, queue)
- **Hotwire** (Turbo + Stimulus) for interactivity

### SQLite-Powered Services
- **Database**: SQLite3 (primary data)
- **Solid Cache**: SQLite-backed Rails cache
- **Solid Queue**: SQLite-backed background jobs
- **Solid Cable**: SQLite-backed Action Cable (if needed later)

### Authentication (Dual)
- **Rails 8 Authentication Generator**: Email/password with sessions
- **OmniAuth**: Google OAuth as additional sign-in option

---

## Pre-Flight Checklist

Before starting, ensure you have:
- [x] Ruby 3.3+ installed (`ruby -v`)
- [x] Rails 8.0+ installed (`rails -v`)
- [x] Git installed (`git --version`)
- [x] SQLite3 installed (`sqlite3 --version`)

**No Node.js required!**

---

## PHASE 1: Project Foundation

### Step 1.1: Create Rails Application

**Command:**
```bash
rails new tech-events-rails \
  --database=sqlite3 \
  --skip-action-cable \
  --skip-action-mailbox \
  --skip-active-storage \
  --skip-jbuilder \
  --skip-test \
  --skip-system-test
```

**What this does:**
- Creates Rails 8 app with SQLite
- Skips unused features (keeps it lean)
- Uses Propshaft + Importmaps by default (no Node.js!)

**Verification:**
```bash
cd tech-events-rails
bin/rails server
# Visit http://localhost:3000 - should see Rails welcome page
```

**Checklist:**
- [ ] App created without errors
- [ ] `bin/rails server` starts
- [ ] Browser shows Rails welcome page
- [ ] No `node_modules` folder exists (confirms no-build)

---

### Step 1.2: Configure Application Basics

**File: `config/application.rb`**
Add inside the `Application` class:
```ruby
# Set timezone to New Zealand
config.time_zone = 'Auckland'

# Use SQLite for all caching and queuing
config.active_job.queue_adapter = :solid_queue
config.cache_store = :solid_cache_store
```

**File: `config/environments/development.rb`**
Ensure caching is enabled for development testing:
```ruby
# Enable caching in development (already wrapped in if block)
config.action_controller.perform_caching = true
config.cache_store = :solid_cache_store
```

**Verification:**
```bash
bin/rails runner "puts Time.zone.name"
# Should output: Auckland
```

**Checklist:**
- [ ] Timezone set to Auckland
- [ ] Server still starts without errors

---

### Step 1.3: Add Pico CSS (No Build Required)

**File: `app/views/layouts/application.html.erb`**
Replace the entire file:
```erb
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><%= content_for(:title) || "NZ Tech Events" %></title>

    <!-- Pico CSS - Classless CSS Framework -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">

    <!-- Custom styles -->
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>

    <!-- Importmaps for JS (no build!) -->
    <%= javascript_importmap_tags %>

    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
  </head>

  <body>
    <header class="container">
      <nav>
        <ul>
          <li><strong><a href="/">NZ Tech Events</a></strong></li>
        </ul>
        <ul>
          <li><a href="/past">Past Events</a></li>
          <% if logged_in? %>
            <li><a href="/events/new" role="button">Post Event</a></li>
            <li><%= button_to "Sign Out", logout_path, method: :delete, form: { style: "display:inline" } %></li>
          <% else %>
            <li><a href="/login">Sign In</a></li>
          <% end %>
        </ul>
      </nav>
    </header>

    <main class="container">
      <% if notice.present? %>
        <article role="alert" aria-label="Notice">
          <%= notice %>
        </article>
      <% end %>
      <% if alert.present? %>
        <article role="alert" aria-label="Alert" style="--pico-background-color: #fecaca; --pico-color: #991b1b;">
          <%= alert %>
        </article>
      <% end %>

      <%= yield %>
    </main>

    <footer class="container">
      <small>NZ Tech Events &copy; <%= Date.current.year %></small>
    </footer>
  </body>
</html>
```

**File: `app/assets/stylesheets/application.css`**
```css
/* Custom styles for NZ Tech Events */

/* Event type badges */
.badge {
  display: inline-block;
  padding: 0.25rem 0.5rem;
  font-size: 0.75rem;
  font-weight: 600;
  border-radius: 0.25rem;
  text-transform: capitalize;
}

.badge-conference { background: #ddd6fe; color: #5b21b6; }
.badge-meetup { background: #d1fae5; color: #065f46; }
.badge-workshop { background: #fef3c7; color: #92400e; }
.badge-hackathon { background: #fee2e2; color: #991b1b; }
.badge-webinar { background: #cffafe; color: #0e7490; }
.badge-networking { background: #fce7f3; color: #9d174d; }
.badge-other { background: #f3f4f6; color: #374151; }

/* Cost badge */
.badge-free { background: #d1fae5; color: #065f46; }
.badge-paid { background: #e0e7ff; color: #3730a3; }

/* Event cards */
.event-card {
  margin-bottom: 1rem;
  padding: 1.5rem;
  border: 1px solid var(--pico-muted-border-color);
  border-radius: 0.5rem;
}

.event-card:hover {
  border-color: var(--pico-primary);
}

.event-card h3 {
  margin-bottom: 0.5rem;
}

.event-meta {
  color: var(--pico-muted-color);
  font-size: 0.875rem;
  margin-bottom: 0.5rem;
}

/* Filter bar */
.filters {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
  margin-bottom: 2rem;
  padding: 1rem;
  background: var(--pico-card-background-color);
  border-radius: 0.5rem;
}

.filters select {
  margin-bottom: 0;
}

/* Utility classes */
.mb-0 { margin-bottom: 0; }
.mb-1 { margin-bottom: 0.5rem; }
.mb-2 { margin-bottom: 1rem; }
.mt-2 { margin-top: 1rem; }
.flex { display: flex; }
.gap-1 { gap: 0.5rem; }
.justify-between { justify-content: space-between; }
.items-center { align-items: center; }
```

**Verification:**
```bash
bin/rails server
# Visit http://localhost:3000 - should see styled page (with navigation)
```

**Note:** The page will show an error about `logged_in?` - that's expected, we'll fix it next.

**Checklist:**
- [ ] Pico CSS loads from CDN
- [ ] Custom CSS file exists
- [ ] No JavaScript build errors in console

---

## PHASE 2: Authentication System

### Step 2.1: Generate Rails 8 Authentication

**Command:**
```bash
bin/rails generate authentication
```

**What this creates:**
- `User` model with `email_address` and `password_digest`
- `Session` model for session management
- `SessionsController` for login/logout
- `PasswordsController` for password resets
- `Authentication` concern with `current_user`, etc.
- Database migrations

**Important:** Rails 8 auth uses `email_address` not `email`. We'll keep this convention.

**Verification:**
```bash
bin/rails db:migrate
bin/rails runner "puts User.column_names"
# Should show: id, email_address, password_digest, created_at, updated_at
```

**Checklist:**
- [ ] Authentication generator ran successfully
- [ ] Migration completed
- [ ] User model exists with email_address and password_digest

---

### Step 2.2: Extend User Model for OAuth and Profile

**Command:**
```bash
bin/rails generate migration AddFieldsToUsers name:string google_uid:string avatar_url:string
```

**File: Edit the generated migration to add indexes:**
```ruby
class AddFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :name, :string
    add_column :users, :google_uid, :string
    add_column :users, :avatar_url, :string

    add_index :users, :google_uid, unique: true, where: "google_uid IS NOT NULL"
  end
end
```

**Run migration:**
```bash
bin/rails db:migrate
```

**File: `app/models/user.rb`**
Update to:
```ruby
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :events, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true

  # Name is required for OAuth users, optional for email users (they can set it later)
  validates :name, presence: true, if: :google_uid?

  # For display purposes
  def display_name
    name.presence || email_address.split('@').first
  end

  # Check if user signed up via Google
  def google_user?
    google_uid.present?
  end
end
```

**Verification:**
```bash
bin/rails runner "u = User.new(email_address: 'test@example.com', password: 'password123'); puts u.valid?"
# Should output: true
```

**Checklist:**
- [ ] Migration added name, google_uid, avatar_url
- [ ] User model has events association
- [ ] User validations work

---

### Step 2.3: Update Application Controller

**File: `app/controllers/application_controller.rb`**
```ruby
class ApplicationController < ActionController::Base
  include Authentication

  helper_method :logged_in?

  private

  def logged_in?
    Current.user.present?
  end

  def require_login
    unless logged_in?
      redirect_to login_path, alert: "Please sign in to continue."
    end
  end
end
```

**File: `app/controllers/concerns/authentication.rb`**
The generator created this. Verify it has `current_user` available via `Current.user`.

**Verification:**
```bash
bin/rails server
# Visit http://localhost:3000 - should load without errors now
```

**Checklist:**
- [ ] `logged_in?` helper available
- [ ] No errors on homepage

---

### Step 2.4: Create Registration Controller

**Command:**
```bash
bin/rails generate controller Registrations new create
```

**File: `app/controllers/registrations_controller.rb`**
```ruby
class RegistrationsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      start_new_session_for(@user)
      redirect_to root_path, notice: "Account created successfully! Welcome to NZ Tech Events."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation, :name)
  end
end
```

**File: `app/views/registrations/new.html.erb`**
```erb
<% content_for :title, "Sign Up - NZ Tech Events" %>

<article style="max-width: 400px; margin: 2rem auto;">
  <header>
    <h1>Create Account</h1>
    <p>Join NZ Tech Events to post and manage events.</p>
  </header>

  <%= form_with model: @user, url: registration_path do |f| %>
    <% if @user.errors.any? %>
      <article role="alert" style="--pico-background-color: #fecaca; --pico-color: #991b1b;">
        <ul style="margin: 0; padding-left: 1rem;">
          <% @user.errors.full_messages.each do |msg| %>
            <li><%= msg %></li>
          <% end %>
        </ul>
      </article>
    <% end %>

    <label for="user_name">
      Name (optional)
      <%= f.text_field :name, placeholder: "Your name" %>
    </label>

    <label for="user_email_address">
      Email *
      <%= f.email_field :email_address, required: true, placeholder: "you@example.com" %>
    </label>

    <label for="user_password">
      Password * <small>(minimum 8 characters)</small>
      <%= f.password_field :password, required: true, minlength: 8 %>
    </label>

    <label for="user_password_confirmation">
      Confirm Password *
      <%= f.password_field :password_confirmation, required: true %>
    </label>

    <%= f.submit "Create Account" %>
  <% end %>

  <hr>

  <p style="text-align: center;">
    Already have an account? <a href="<%= login_path %>">Sign in</a>
  </p>

  <p style="text-align: center;">
    Or sign in with:
    <%= button_to "Google", "/auth/google_oauth2", method: :post, data: { turbo: false }, form: { style: "display: inline" } %>
  </p>
</article>
```

**Verification:**
```bash
bin/rails server
# Visit http://localhost:3000/registrations/new
# Form should display (Google button won't work yet)
```

**Checklist:**
- [ ] Registration form displays
- [ ] Form has email, password, name fields

---

### Step 2.5: Update Sessions Views

**File: `app/views/sessions/new.html.erb`**
```erb
<% content_for :title, "Sign In - NZ Tech Events" %>

<article style="max-width: 400px; margin: 2rem auto;">
  <header>
    <h1>Sign In</h1>
    <p>Welcome back to NZ Tech Events.</p>
  </header>

  <%= form_with url: session_path do |f| %>
    <label for="email_address">
      Email
      <%= f.email_field :email_address, required: true, autofocus: true, placeholder: "you@example.com" %>
    </label>

    <label for="password">
      Password
      <%= f.password_field :password, required: true %>
    </label>

    <%= f.submit "Sign In" %>
  <% end %>

  <hr>

  <p style="text-align: center;">
    Don't have an account? <a href="<%= new_registration_path %>">Sign up</a>
  </p>

  <p style="text-align: center;">
    Or sign in with:
    <%= button_to "Google", "/auth/google_oauth2", method: :post, data: { turbo: false }, form: { style: "display: inline" } %>
  </p>
</article>
```

**Checklist:**
- [ ] Login page displays
- [ ] Links to registration

---

### Step 2.6: Add Google OAuth

**File: `Gemfile`**
Add these gems:
```ruby
# OAuth authentication
gem "omniauth"
gem "omniauth-google-oauth2"
gem "omniauth-rails_csrf_protection"
```

**Command:**
```bash
bundle install
```

**File: `config/initializers/omniauth.rb`** (create new file)
```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
    ENV.fetch("GOOGLE_CLIENT_ID", nil),
    ENV.fetch("GOOGLE_CLIENT_SECRET", nil),
    {
      scope: "email,profile",
      prompt: "select_account",
      image_aspect_ratio: "square",
      image_size: 96
    }
end

# Allow both GET and POST for OAuth callbacks
OmniAuth.config.allowed_request_methods = [:post, :get]

# Handle OAuth failures gracefully
OmniAuth.config.on_failure = Proc.new { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}
```

**File: `app/controllers/oauth_callbacks_controller.rb`** (create new file)
```ruby
class OauthCallbacksController < ApplicationController
  def google_oauth2
    auth = request.env["omniauth.auth"]

    # Find existing user by Google UID or email
    user = User.find_by(google_uid: auth["uid"]) ||
           User.find_by(email_address: auth["info"]["email"])

    if user
      # Update Google info if linking existing email account
      unless user.google_uid
        user.update(
          google_uid: auth["uid"],
          avatar_url: auth["info"]["image"]
        )
      end
      # Update name if not set
      user.update(name: auth["info"]["name"]) if user.name.blank?
    else
      # Create new user from Google
      user = User.create!(
        email_address: auth["info"]["email"],
        name: auth["info"]["name"],
        google_uid: auth["uid"],
        avatar_url: auth["info"]["image"],
        password: SecureRandom.hex(16) # Random password for OAuth users
      )
    end

    start_new_session_for(user)
    redirect_to root_path, notice: "Signed in with Google successfully!"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to login_path, alert: "Could not sign in with Google: #{e.message}"
  end

  def failure
    redirect_to login_path, alert: "Google authentication failed. Please try again."
  end
end
```

**File: `config/routes.rb`**
Update to:
```ruby
Rails.application.routes.draw do
  # Root
  root "events#index"

  # Authentication (email/password)
  get  "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  # Registration
  get  "signup", to: "registrations#new", as: :new_registration
  post "signup", to: "registrations#create", as: :registration

  # OAuth callbacks
  get  "/auth/google_oauth2/callback", to: "oauth_callbacks#google_oauth2"
  get  "/auth/failure", to: "oauth_callbacks#failure"
  post "/auth/google_oauth2", to: -> (env) { [404, {}, ["Not found"]] } # OmniAuth handles this

  # Password resets (from Rails 8 generator)
  resources :passwords, param: :token

  # Events (placeholder - will implement next phase)
  resources :events do
    collection do
      get :past
    end
  end

  # Health check for deployment
  get "up", to: proc { [200, {}, ["OK"]] }
end
```

**Verification:**
```bash
bin/rails server
# Visit http://localhost:3000/signup
# Create account with email/password
# Should redirect to homepage, logged in
```

**Checklist:**
- [ ] Email signup works
- [ ] Login works
- [ ] Logout works
- [ ] Google OAuth gems installed (Google button won't work without credentials)

---

### Step 2.7: Update Layout Navigation

**File: `app/views/layouts/application.html.erb`**
Update the nav section to use correct helpers:
```erb
<header class="container">
  <nav>
    <ul>
      <li><strong><a href="<%= root_path %>">NZ Tech Events</a></strong></li>
    </ul>
    <ul>
      <li><a href="<%= past_events_path %>">Past Events</a></li>
      <% if logged_in? %>
        <li><a href="<%= new_event_path %>" role="button">Post Event</a></li>
        <li>
          <details class="dropdown">
            <summary><%= Current.user&.display_name || "Account" %></summary>
            <ul dir="rtl">
              <li><%= button_to "Sign Out", logout_path, method: :delete %></li>
            </ul>
          </details>
        </li>
      <% else %>
        <li><a href="<%= login_path %>">Sign In</a></li>
        <li><a href="<%= new_registration_path %>" role="button">Sign Up</a></li>
      <% end %>
    </ul>
  </nav>
</header>
```

**Checklist:**
- [ ] Navigation shows Sign In/Sign Up when logged out
- [ ] Navigation shows Post Event and user name when logged in

---

## PHASE 3: Event Model & Database

### Step 3.1: Generate Event Model

**Command:**
```bash
bin/rails generate model Event \
  title:string \
  description:text \
  start_date:date \
  end_date:date \
  start_time:time \
  end_time:time \
  cost:string \
  event_type:integer \
  registration_url:string \
  region:integer \
  city:string \
  address:text \
  user:references
```

**File: Edit the migration before running:**
`db/migrate/[timestamp]_create_events.rb`
```ruby
class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.string :title, null: false
      t.text :description, null: false
      t.date :start_date, null: false
      t.date :end_date
      t.time :start_time
      t.time :end_time
      t.string :cost
      t.integer :event_type, null: false, default: 0
      t.string :registration_url
      t.integer :region, null: false
      t.string :city, null: false
      t.text :address
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :events, :start_date
    add_index :events, :region
    add_index :events, [:start_date, :region]
    add_index :events, :event_type
  end
end
```

**Command:**
```bash
bin/rails db:migrate
```

**Verification:**
```bash
bin/rails runner "puts Event.column_names.join(', ')"
# Should show all columns
```

**Checklist:**
- [ ] Events table created with all columns
- [ ] Indexes added
- [ ] Foreign key to users exists

---

### Step 3.2: Configure Event Model

**File: `app/models/event.rb`**
```ruby
class Event < ApplicationRecord
  belongs_to :user

  # Enums
  enum :event_type, {
    conference: 0,
    meetup: 1,
    workshop: 2,
    hackathon: 3,
    webinar: 4,
    networking: 5,
    other: 6
  }, prefix: true

  enum :region, {
    northland: 0,
    auckland: 1,
    waikato: 2,
    bay_of_plenty: 3,
    gisborne: 4,
    hawkes_bay: 5,
    taranaki: 6,
    manawatu_whanganui: 7,
    wellington: 8,
    tasman: 9,
    nelson: 10,
    marlborough: 11,
    west_coast: 12,
    canterbury: 13,
    otago: 14,
    southland: 15,
    online: 16
  }, prefix: true

  # Validations
  validates :title, presence: true, length: { maximum: 200 }
  validates :description, presence: true
  validates :start_date, presence: true
  validates :event_type, presence: true
  validates :region, presence: true
  validates :city, presence: true

  validate :end_date_after_start_date, if: -> { end_date.present? }

  # Scopes
  scope :upcoming, -> { where("start_date >= ?", Date.current).order(start_date: :asc, start_time: :asc) }
  scope :past, -> { where("start_date < ?", Date.current).order(start_date: :desc, start_time: :desc) }
  scope :by_region, ->(region) { where(region: region) if region.present? }
  scope :by_city, ->(city) { where(city: city) if city.present? }
  scope :by_event_type, ->(type) { where(event_type: type) if type.present? }

  # Instance methods
  def owned_by?(check_user)
    user_id == check_user&.id
  end

  def multi_day?
    end_date.present? && end_date != start_date
  end

  def free?
    cost.blank? || cost.downcase.include?("free")
  end

  def formatted_date
    if multi_day?
      "#{start_date.strftime('%d %b')} - #{end_date.strftime('%d %b %Y')}"
    else
      start_date.strftime("%A, %d %B %Y")
    end
  end

  def formatted_time
    return nil unless start_time

    if end_time && end_time != start_time
      "#{start_time.strftime('%l:%M %p').strip} - #{end_time.strftime('%l:%M %p').strip}"
    else
      start_time.strftime("%l:%M %p").strip
    end
  end

  def region_display
    region.to_s.titleize.gsub("_", "-")
  end

  private

  def end_date_after_start_date
    if end_date < start_date
      errors.add(:end_date, "must be after start date")
    end
  end
end
```

**Verification:**
```bash
bin/rails runner "
  u = User.first || User.create!(email_address: 'test@test.com', password: 'password123')
  e = Event.new(
    title: 'Test Event',
    description: 'A test event',
    start_date: Date.tomorrow,
    event_type: :meetup,
    region: :auckland,
    city: 'Auckland CBD',
    user: u
  )
  puts e.valid?
  puts e.errors.full_messages if e.invalid?
"
# Should output: true
```

**Checklist:**
- [ ] Event model has all enums
- [ ] Validations work
- [ ] Scopes defined
- [ ] Helper methods work

---

### Step 3.3: Create Regions Helper

**File: `app/helpers/events_helper.rb`**
```ruby
module EventsHelper
  CITIES_BY_REGION = {
    "northland" => ["Whangārei", "Kerikeri", "Kaitaia", "Other"],
    "auckland" => ["Auckland CBD", "North Shore", "West Auckland", "South Auckland", "East Auckland", "Other"],
    "waikato" => ["Hamilton", "Cambridge", "Te Awamutu", "Other"],
    "bay_of_plenty" => ["Tauranga", "Rotorua", "Whakatāne", "Other"],
    "gisborne" => ["Gisborne", "Other"],
    "hawkes_bay" => ["Napier", "Hastings", "Other"],
    "taranaki" => ["New Plymouth", "Hāwera", "Other"],
    "manawatu_whanganui" => ["Palmerston North", "Whanganui", "Other"],
    "wellington" => ["Wellington CBD", "Lower Hutt", "Upper Hutt", "Porirua", "Kāpiti Coast", "Other"],
    "tasman" => ["Richmond", "Motueka", "Other"],
    "nelson" => ["Nelson", "Other"],
    "marlborough" => ["Blenheim", "Other"],
    "west_coast" => ["Greymouth", "Hokitika", "Other"],
    "canterbury" => ["Christchurch", "Timaru", "Ashburton", "Other"],
    "otago" => ["Dunedin", "Queenstown", "Wānaka", "Other"],
    "southland" => ["Invercargill", "Gore", "Other"],
    "online" => ["Online"]
  }.freeze

  def cities_for_region(region)
    CITIES_BY_REGION[region.to_s] || []
  end

  def cities_json
    CITIES_BY_REGION.to_json.html_safe
  end

  def region_options
    Event.regions.keys.map { |r| [r.titleize.gsub("_", "-"), r] }
  end

  def event_type_options
    Event.event_types.keys.map { |t| [t.titleize, t] }
  end

  def event_type_badge_class(event_type)
    "badge badge-#{event_type}"
  end
end
```

**Checklist:**
- [ ] Helper created with all NZ cities
- [ ] JSON export for JavaScript

---

## PHASE 4: Events Controller & Views

### Step 4.1: Create Events Controller

**File: `app/controllers/events_controller.rb`**
```ruby
class EventsController < ApplicationController
  before_action :require_login, only: [:new, :create, :edit, :update, :destroy]
  before_action :set_event, only: [:show, :edit, :update, :destroy]
  before_action :authorize_owner!, only: [:edit, :update, :destroy]

  def index
    @events = Event.upcoming.includes(:user)
    apply_filters
  end

  def past
    @events = Event.past.includes(:user)
    apply_filters
  end

  def show
  end

  def new
    @event = Current.user.events.build
    @event.start_date = Date.tomorrow
  end

  def create
    @event = Current.user.events.build(event_params)

    if @event.save
      redirect_to @event, notice: "Event created successfully!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @event.update(event_params)
      redirect_to @event, notice: "Event updated successfully!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @event.destroy
    redirect_to root_path, notice: "Event deleted successfully!"
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def authorize_owner!
    unless @event.owned_by?(Current.user)
      redirect_to root_path, alert: "You are not authorized to modify this event."
    end
  end

  def event_params
    params.require(:event).permit(
      :title, :description, :start_date, :end_date,
      :start_time, :end_time, :cost, :event_type,
      :registration_url, :region, :city, :address
    )
  end

  def apply_filters
    @events = @events.by_region(params[:region]) if params[:region].present?
    @events = @events.by_city(params[:city]) if params[:city].present?
    @events = @events.by_event_type(params[:event_type]) if params[:event_type].present?
  end
end
```

**Checklist:**
- [ ] Controller has all CRUD actions
- [ ] Filters implemented
- [ ] Authorization checks in place

---

### Step 4.2: Create Event Views - Index

**File: `app/views/events/index.html.erb`**
```erb
<% content_for :title, "Upcoming Tech Events in New Zealand" %>

<h1>Upcoming Events</h1>

<%= render "filters" %>

<% if @events.any? %>
  <div class="events-list">
    <%= render partial: "event_card", collection: @events, as: :event %>
  </div>
<% else %>
  <article style="text-align: center; padding: 3rem;">
    <h3>No upcoming events</h3>
    <p>Be the first to post an event!</p>
    <% if logged_in? %>
      <a href="<%= new_event_path %>" role="button">Post an Event</a>
    <% else %>
      <a href="<%= new_registration_path %>" role="button">Sign up to post events</a>
    <% end %>
  </article>
<% end %>
```

**File: `app/views/events/past.html.erb`**
```erb
<% content_for :title, "Past Tech Events in New Zealand" %>

<h1>Past Events</h1>

<%= render "filters" %>

<% if @events.any? %>
  <div class="events-list">
    <%= render partial: "event_card", collection: @events, as: :event %>
  </div>
<% else %>
  <article style="text-align: center; padding: 3rem;">
    <h3>No past events found</h3>
    <p><a href="<%= root_path %>">View upcoming events</a></p>
  </article>
<% end %>
```

**Checklist:**
- [ ] Index view created
- [ ] Past events view created

---

### Step 4.3: Create Event Partials

**File: `app/views/events/_filters.html.erb`**
```erb
<%= form_with url: request.path, method: :get, data: { turbo_frame: "_top", controller: "filter" } do |f| %>
  <div class="filters">
    <div>
      <label for="region" class="mb-0">Region</label>
      <%= select_tag :region,
          options_for_select([["All Regions", ""]] + region_options, params[:region]),
          data: { action: "change->filter#regionChanged", filter_target: "region" } %>
    </div>

    <div>
      <label for="city" class="mb-0">City</label>
      <%= select_tag :city,
          options_for_select([["All Cities", ""]] + (params[:region].present? ? cities_for_region(params[:region]).map { |c| [c, c] } : []), params[:city]),
          data: { filter_target: "city" } %>
    </div>

    <div>
      <label for="event_type" class="mb-0">Type</label>
      <%= select_tag :event_type,
          options_for_select([["All Types", ""]] + event_type_options, params[:event_type]) %>
    </div>

    <div style="display: flex; align-items: flex-end;">
      <%= submit_tag "Filter", name: nil %>
      <% if params[:region].present? || params[:city].present? || params[:event_type].present? %>
        <a href="<%= request.path %>" style="margin-left: 0.5rem;">Clear</a>
      <% end %>
    </div>
  </div>
<% end %>

<script type="text/javascript">
  // Inline script for filter (will be moved to Stimulus controller)
  const citiesByRegion = <%= cities_json %>;

  document.addEventListener('DOMContentLoaded', function() {
    const regionSelect = document.querySelector('[data-filter-target="region"]');
    const citySelect = document.querySelector('[data-filter-target="city"]');

    if (regionSelect && citySelect) {
      regionSelect.addEventListener('change', function() {
        const region = this.value;
        const cities = citiesByRegion[region] || [];

        citySelect.innerHTML = '<option value="">All Cities</option>';
        cities.forEach(function(city) {
          const option = document.createElement('option');
          option.value = city;
          option.textContent = city;
          citySelect.appendChild(option);
        });
      });
    }
  });
</script>
```

**File: `app/views/events/_event_card.html.erb`**
```erb
<article class="event-card">
  <div class="flex justify-between items-center mb-1">
    <span class="<%= event_type_badge_class(event.event_type) %>">
      <%= event.event_type.titleize %>
    </span>
    <span class="badge <%= event.free? ? 'badge-free' : 'badge-paid' %>">
      <%= event.cost.presence || "Free" %>
    </span>
  </div>

  <h3 class="mb-0">
    <a href="<%= event_path(event) %>"><%= event.title %></a>
  </h3>

  <p class="event-meta">
    📅 <%= event.formatted_date %>
    <% if event.formatted_time %>
      · ⏰ <%= event.formatted_time %>
    <% end %>
    <br>
    📍 <%= event.city %>, <%= event.region_display %>
  </p>

  <p><%= truncate(event.description, length: 200) %></p>
</article>
```

**Checklist:**
- [ ] Filter partial with region/city/type filters
- [ ] Event card partial with all info

---

### Step 4.4: Create Event Show Page

**File: `app/views/events/show.html.erb`**
```erb
<% content_for :title, "#{@event.title} - NZ Tech Events" %>

<p><a href="<%= root_path %>">&larr; Back to Events</a></p>

<article>
  <header>
    <span class="<%= event_type_badge_class(@event.event_type) %>">
      <%= @event.event_type.titleize %>
    </span>

    <h1><%= @event.title %></h1>
  </header>

  <div class="event-details">
    <p>
      <strong>📅 Date:</strong> <%= @event.formatted_date %><br>
      <% if @event.formatted_time %>
        <strong>⏰ Time:</strong> <%= @event.formatted_time %><br>
      <% end %>
      <strong>📍 Location:</strong> <%= @event.city %>, <%= @event.region_display %>
      <% if @event.address.present? %>
        <br><small><%= @event.address %></small>
      <% end %>
    </p>

    <p>
      <strong>💰 Cost:</strong>
      <span class="badge <%= @event.free? ? 'badge-free' : 'badge-paid' %>">
        <%= @event.cost.presence || "Free" %>
      </span>
    </p>

    <% if @event.registration_url.present? %>
      <p>
        <a href="<%= @event.registration_url %>" target="_blank" rel="noopener noreferrer" role="button">
          Register / Get Tickets &rarr;
        </a>
      </p>
    <% end %>
  </div>

  <hr>

  <div class="event-description">
    <%= simple_format(@event.description) %>
  </div>

  <hr>

  <footer>
    <small>
      Posted by <%= @event.user.display_name %>
      on <%= @event.created_at.strftime("%d %B %Y") %>
    </small>

    <% if @event.owned_by?(Current.user) %>
      <div class="mt-2">
        <a href="<%= edit_event_path(@event) %>" role="button" class="outline">Edit</a>
        <%= button_to "Delete", event_path(@event),
            method: :delete,
            data: { turbo_confirm: "Are you sure you want to delete this event?" },
            class: "outline secondary" %>
      </div>
    <% end %>
  </footer>
</article>
```

**Checklist:**
- [ ] Show page displays all event details
- [ ] Edit/Delete buttons only for owner

---

### Step 4.5: Create Event Form

**File: `app/views/events/new.html.erb`**
```erb
<% content_for :title, "Post New Event - NZ Tech Events" %>

<h1>Post New Event</h1>

<%= render "form", event: @event %>
```

**File: `app/views/events/edit.html.erb`**
```erb
<% content_for :title, "Edit Event - NZ Tech Events" %>

<h1>Edit Event</h1>

<%= render "form", event: @event %>

<hr>

<p>
  <a href="<%= event_path(@event) %>">&larr; Back to event</a>
</p>
```

**File: `app/views/events/_form.html.erb`**
```erb
<%= form_with model: event, data: { controller: "event-form" } do |f| %>
  <% if event.errors.any? %>
    <article role="alert" style="--pico-background-color: #fecaca; --pico-color: #991b1b;">
      <strong>Please fix the following errors:</strong>
      <ul style="margin: 0.5rem 0 0 1rem;">
        <% event.errors.full_messages.each do |msg| %>
          <li><%= msg %></li>
        <% end %>
      </ul>
    </article>
  <% end %>

  <fieldset>
    <legend>Event Details</legend>

    <label for="event_title">
      Title *
      <%= f.text_field :title, required: true, placeholder: "e.g., Auckland JavaScript Meetup" %>
    </label>

    <label for="event_event_type">
      Event Type *
      <%= f.select :event_type, event_type_options, { prompt: "Select type..." }, { required: true } %>
    </label>

    <label for="event_description">
      Description *
      <%= f.text_area :description, required: true, rows: 6, placeholder: "Tell people what this event is about..." %>
    </label>
  </fieldset>

  <fieldset>
    <legend>Date & Time</legend>

    <div class="grid">
      <label for="event_start_date">
        Start Date *
        <%= f.date_field :start_date, required: true %>
      </label>

      <label for="event_end_date">
        End Date <small>(for multi-day events)</small>
        <%= f.date_field :end_date %>
      </label>
    </div>

    <div class="grid">
      <label for="event_start_time">
        Start Time
        <%= f.time_field :start_time %>
      </label>

      <label for="event_end_time">
        End Time
        <%= f.time_field :end_time %>
      </label>
    </div>
  </fieldset>

  <fieldset>
    <legend>Location</legend>

    <div class="grid">
      <label for="event_region">
        Region *
        <%= f.select :region, region_options, { prompt: "Select region..." },
            { required: true, data: { action: "change->event-form#regionChanged", event_form_target: "region" } } %>
      </label>

      <label for="event_city">
        City *
        <%= f.select :city,
            event.region.present? ? cities_for_region(event.region).map { |c| [c, c] } : [],
            { prompt: "Select city..." },
            { required: true, data: { event_form_target: "city" } } %>
      </label>
    </div>

    <label for="event_address">
      Address / Venue <small>(optional)</small>
      <%= f.text_area :address, rows: 2, placeholder: "e.g., GridAKL, 12 Madden Street, Auckland" %>
    </label>
  </fieldset>

  <fieldset>
    <legend>Additional Info</legend>

    <label for="event_cost">
      Cost <small>(leave blank for free events)</small>
      <%= f.text_field :cost, placeholder: "e.g., Free, $20, $50-100, Koha" %>
    </label>

    <label for="event_registration_url">
      Registration Link <small>(optional)</small>
      <%= f.url_field :registration_url, placeholder: "https://..." %>
    </label>
  </fieldset>

  <div class="flex gap-1">
    <%= f.submit event.persisted? ? "Update Event" : "Create Event" %>
    <a href="<%= event.persisted? ? event_path(event) : root_path %>" role="button" class="outline secondary">Cancel</a>
  </div>
<% end %>

<script type="text/javascript">
  // Inline script for form (can be moved to Stimulus controller later)
  const citiesByRegion = <%= cities_json %>;

  document.addEventListener('DOMContentLoaded', function() {
    const regionSelect = document.querySelector('[data-event-form-target="region"]');
    const citySelect = document.querySelector('[data-event-form-target="city"]');

    if (regionSelect && citySelect) {
      regionSelect.addEventListener('change', function() {
        const region = this.value;
        const cities = citiesByRegion[region] || [];

        citySelect.innerHTML = '<option value="">Select city...</option>';
        cities.forEach(function(city) {
          const option = document.createElement('option');
          option.value = city;
          option.textContent = city;
          citySelect.appendChild(option);
        });
      });
    }
  });
</script>
```

**Verification:**
```bash
bin/rails server
# Create account, create event, verify it shows up
```

**Checklist:**
- [ ] New event form works
- [ ] Edit event form works
- [ ] Dynamic city dropdown works
- [ ] Validation errors display

---

## PHASE 5: Solid Queue & Solid Cache Setup

### Step 5.1: Configure Solid Cache

**File: `Gemfile`**
Ensure these are present (should be default in Rails 8):
```ruby
gem "solid_cache"
gem "solid_queue"
```

**Command:**
```bash
bundle install
bin/rails solid_cache:install
bin/rails solid_queue:install
```

**Run migrations:**
```bash
bin/rails db:migrate
```

**File: `config/cache.yml`** (if not created)
```yaml
default: &default
  store_options:
    max_age: <%= 1.week.to_i %>
    max_size: <%= 256.megabytes %>
    namespace: <%= Rails.env %>

development:
  <<: *default

production:
  <<: *default
```

**Verification:**
```bash
bin/rails runner "Rails.cache.write('test', 'value'); puts Rails.cache.read('test')"
# Should output: value
```

**Checklist:**
- [ ] Solid Cache installed and working
- [ ] Solid Queue installed

---

### Step 5.2: Configure Database for All Services

**File: `config/database.yml`**
```yaml
default: &default
  adapter: sqlite3
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000

development:
  primary:
    <<: *default
    database: storage/development.sqlite3
  cache:
    <<: *default
    database: storage/development_cache.sqlite3
    migrations_paths: db/cache_migrate
  queue:
    <<: *default
    database: storage/development_queue.sqlite3
    migrations_paths: db/queue_migrate

test:
  primary:
    <<: *default
    database: storage/test.sqlite3
  cache:
    <<: *default
    database: storage/test_cache.sqlite3
    migrations_paths: db/cache_migrate
  queue:
    <<: *default
    database: storage/test_queue.sqlite3
    migrations_paths: db/queue_migrate

production:
  primary:
    <<: *default
    database: storage/production.sqlite3
  cache:
    <<: *default
    database: storage/production_cache.sqlite3
    migrations_paths: db/cache_migrate
  queue:
    <<: *default
    database: storage/production_queue.sqlite3
    migrations_paths: db/queue_migrate
```

**Verification:**
```bash
bin/rails db:prepare
bin/rails server
```

**Checklist:**
- [ ] Multiple SQLite databases configured
- [ ] App starts without errors

---

## PHASE 6: Stimulus Controllers (Optional Enhancement)

### Step 6.1: Create Filter Controller

**File: `app/javascript/controllers/filter_controller.js`**
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["region", "city"]
  static values = { cities: Object }

  connect() {
    // Initialize cities data from the page
    this.citiesValue = JSON.parse(document.querySelector('[data-cities]')?.dataset.cities || '{}')
  }

  regionChanged() {
    const region = this.regionTarget.value
    const cities = this.citiesValue[region] || []

    this.cityTarget.innerHTML = '<option value="">All Cities</option>'
    cities.forEach(city => {
      const option = document.createElement('option')
      option.value = city
      option.textContent = city
      this.cityTarget.appendChild(option)
    })
  }
}
```

**File: `app/javascript/controllers/event_form_controller.js`**
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["region", "city"]
  static values = { cities: Object }

  connect() {
    this.citiesValue = JSON.parse(document.querySelector('[data-cities]')?.dataset.cities || '{}')
  }

  regionChanged() {
    const region = this.regionTarget.value
    const cities = this.citiesValue[region] || []

    this.cityTarget.innerHTML = '<option value="">Select city...</option>'
    cities.forEach(city => {
      const option = document.createElement('option')
      option.value = city
      option.textContent = city
      this.cityTarget.appendChild(option)
    })
  }
}
```

**Register controllers in `app/javascript/controllers/index.js`**:
```javascript
import { application } from "./application"

import FilterController from "./filter_controller"
import EventFormController from "./event_form_controller"

application.register("filter", FilterController)
application.register("event-form", EventFormController)
```

**Note:** The inline scripts in the views work fine for MVP. Stimulus is optional but cleaner.

**Checklist:**
- [ ] Stimulus controllers created (optional)
- [ ] Dynamic dropdowns work

---

## PHASE 7: Seeds & Testing

### Step 7.1: Create Seed Data

**File: `db/seeds.rb`**
```ruby
# Clear existing data
puts "Clearing existing data..."
Event.destroy_all
User.destroy_all

# Create test user
puts "Creating test user..."
test_user = User.create!(
  email_address: "test@example.com",
  password: "password123",
  name: "Test User"
)

# Create sample events
puts "Creating sample events..."

events_data = [
  {
    title: "Auckland JavaScript Meetup",
    description: "Join us for an evening of JavaScript talks and networking. We'll have two speakers covering modern JS frameworks and best practices for async programming.",
    start_date: Date.current + 7.days,
    start_time: "18:00",
    end_time: "21:00",
    event_type: :meetup,
    region: :auckland,
    city: "Auckland CBD",
    address: "GridAKL, 12 Madden Street",
    cost: "Free"
  },
  {
    title: "Wellington Tech Conference 2025",
    description: "The biggest tech conference in the capital! Two days of talks, workshops, and networking with the best minds in NZ tech.",
    start_date: Date.current + 30.days,
    end_date: Date.current + 31.days,
    start_time: "09:00",
    end_time: "17:00",
    event_type: :conference,
    region: :wellington,
    city: "Wellington CBD",
    address: "Te Papa Museum",
    cost: "$199",
    registration_url: "https://example.com/register"
  },
  {
    title: "Christchurch Python Workshop",
    description: "A hands-on workshop for Python beginners. Learn the basics of Python programming in a friendly, supportive environment.",
    start_date: Date.current + 14.days,
    start_time: "10:00",
    end_time: "16:00",
    event_type: :workshop,
    region: :canterbury,
    city: "Christchurch",
    address: "University of Canterbury",
    cost: "$50"
  },
  {
    title: "Remote Work Webinar",
    description: "Tips and tricks for effective remote work. Join us online to learn from experienced remote workers.",
    start_date: Date.current + 3.days,
    start_time: "12:00",
    end_time: "13:00",
    event_type: :webinar,
    region: :online,
    city: "Online",
    cost: "Free",
    registration_url: "https://zoom.us/example"
  },
  {
    title: "Hamilton Hackathon",
    description: "48-hour hackathon! Build something amazing with fellow developers. Prizes for top projects!",
    start_date: Date.current + 45.days,
    end_date: Date.current + 47.days,
    start_time: "18:00",
    event_type: :hackathon,
    region: :waikato,
    city: "Hamilton",
    address: "Innovation Park, 10 Mill Street",
    cost: "$25"
  },
  {
    title: "Past Meetup Example",
    description: "This is a past event to demonstrate the past events page.",
    start_date: Date.current - 14.days,
    start_time: "18:00",
    end_time: "20:00",
    event_type: :meetup,
    region: :auckland,
    city: "Auckland CBD",
    cost: "Free"
  }
]

events_data.each do |event_data|
  Event.create!(event_data.merge(user: test_user))
  puts "  Created: #{event_data[:title]}"
end

puts "Done! Created #{User.count} user and #{Event.count} events."
puts ""
puts "Login credentials:"
puts "  Email: test@example.com"
puts "  Password: password123"
```

**Command:**
```bash
bin/rails db:seed
```

**Verification:**
```bash
bin/rails server
# Visit http://localhost:3000 - should see sample events
# Visit http://localhost:3000/past - should see past event
```

**Checklist:**
- [ ] Seeds run without errors
- [ ] Events appear on homepage
- [ ] Past events appear on past page

---

## PHASE 8: Final Polish

### Step 8.1: Add Meta Tags

**File: `app/views/layouts/application.html.erb`**
Update the `<head>` section:
```erb
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title><%= content_for(:title) || "NZ Tech Events - Find Tech Events in New Zealand" %></title>
  <meta name="description" content="<%= content_for(:description) || 'Discover and share tech events across New Zealand. Conferences, meetups, workshops, and more.' %>">

  <!-- Open Graph -->
  <meta property="og:title" content="<%= content_for(:title) || 'NZ Tech Events' %>">
  <meta property="og:description" content="<%= content_for(:description) || 'Discover and share tech events across New Zealand.' %>">
  <meta property="og:type" content="website">

  <!-- Favicon -->
  <link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><text y='.9em' font-size='90'>📅</text></svg>">

  <!-- Pico CSS -->
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">

  <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
  <%= javascript_importmap_tags %>
  <%= csrf_meta_tags %>
  <%= csp_meta_tag %>
</head>
```

**Checklist:**
- [ ] Meta tags added
- [ ] Favicon displays (calendar emoji)

---

### Step 8.2: Environment Variables Setup

**File: `.env.example`** (create new file)
```bash
# Google OAuth (get from Google Cloud Console)
GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-client-secret

# Rails (generate with: bin/rails secret)
SECRET_KEY_BASE=your-secret-key-base

# Optional: Set to production for deployment
RAILS_ENV=development
```

**File: `Gemfile`**
Add for local development:
```ruby
group :development do
  gem "dotenv-rails"
end
```

**Command:**
```bash
bundle install
cp .env.example .env
# Edit .env with your values
```

**Checklist:**
- [ ] `.env.example` created
- [ ] `.env` in `.gitignore`
- [ ] dotenv gem installed

---

### Step 8.3: Update .gitignore

**File: `.gitignore`**
Add these lines:
```gitignore
# Environment files
.env
.env.local
.env.*.local

# SQLite databases
/storage/*.sqlite3
/storage/*.sqlite3-*

# Kamal secrets
.kamal/

# IDE
.idea/
.vscode/
*.swp

# OS
.DS_Store
```

**Checklist:**
- [ ] .gitignore updated
- [ ] Sensitive files excluded

---

## Final Verification Checklist

### Functionality Tests
Run through each of these manually:

- [ ] **Homepage loads** - Shows upcoming events or empty state
- [ ] **Past events page** - Shows past events
- [ ] **Sign up (email)** - Create account with email/password
- [ ] **Sign in (email)** - Login works
- [ ] **Sign out** - Logout works
- [ ] **Create event** - Form works, event appears on homepage
- [ ] **View event** - Event detail page shows all info
- [ ] **Edit event** - Owner can edit, non-owner cannot
- [ ] **Delete event** - Owner can delete with confirmation
- [ ] **Filters** - Region/city/type filters work
- [ ] **Dynamic city dropdown** - Updates when region changes

### Technical Checks
- [ ] **No Node.js** - `node_modules` folder does not exist
- [ ] **SQLite only** - Check `storage/` folder has SQLite files
- [ ] **No build errors** - `bin/rails assets:precompile` works
- [ ] **Server starts** - `bin/rails server` works
- [ ] **Console works** - `bin/rails console` works

---

## Quick Start Commands

```bash
# Initial setup
git clone [repo]
cd tech-events-rails
bundle install
bin/rails db:prepare
bin/rails db:seed

# Run locally
bin/rails server
# Visit http://localhost:3000

# Create new user in console
bin/rails console
User.create!(email_address: "you@example.com", password: "password123", name: "Your Name")

# Reset database
bin/rails db:reset
bin/rails db:seed
```

---

## Next Steps

After completing all phases:
1. Set up Google OAuth credentials (optional)
2. Configure Kamal for deployment (see `plan-deployment.md`)
3. Deploy to Hetzner

The app is fully functional without Google OAuth - users can sign up with email/password.
