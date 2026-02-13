# NZ Tech Events - Claude Reference Guide

Quick reference for AI agents and developers working on this project.

---

## Project Overview

A simple New Zealand tech events listing website. Users can browse events, filter by location, and registered users can post events using either email/password or Google sign-in.

**Live URL**: `techevents.co.nz` (when deployed)

---

## Tech Stack (No-Build)

| Component | Technology | Notes |
|-----------|------------|-------|
| Framework | Rails 8.0 | Full-stack, server-rendered |
| Database | SQLite3 | Single file, easy backups |
| Cache | Solid Cache | SQLite-backed |
| Queue | Solid Queue | SQLite-backed |
| CSS | Pico CSS (CDN) | Classless, no build |
| JavaScript | Importmaps | No bundler, no Node.js |
| Interactivity | Hotwire (Turbo + Stimulus) | SPA-like without complexity |
| Auth | Rails 8 Generator + OmniAuth | Email/password + Google |
| Deployment | Kamal 2 | Docker-based, to Hetzner |

**Key Principle**: Zero Node.js. No `node_modules`. No build step.

---

## Quick Start

```bash
# Clone and setup
git clone <repo>
cd tech-events-rails
bundle install
bin/rails db:prepare
bin/rails db:seed

# Run locally
bin/rails server
# Visit http://localhost:3000

# Test credentials
# Email: test@example.com
# Password: password123
```

---

## Database Schema

### Users Table
```sql
users
├── id (integer, PK)
├── email_address (string, unique, not null)  -- Rails 8 convention
├── password_digest (string, not null)
├── name (string, nullable)
├── google_uid (string, unique nullable)
├── avatar_url (string, nullable)
├── created_at, updated_at
```

### Sessions Table (Rails 8 Auth)
```sql
sessions
├── id (integer, PK)
├── user_id (FK)
├── ip_address (string)
├── user_agent (string)
├── created_at, updated_at
```

### Events Table
```sql
events
├── id (integer, PK)
├── title (string, not null, max 200)
├── description (text, not null)
├── start_date (date, not null)
├── end_date (date, nullable)
├── start_time (time, nullable)
├── end_time (time, nullable)
├── cost (string, nullable)
├── event_type (integer, not null)  -- enum
├── registration_url (string, nullable)
├── region (integer, not null)  -- enum
├── city (string, not null)
├── address (text, nullable)
├── user_id (FK, not null)
├── created_at, updated_at

Indexes: start_date, region, [start_date, region], event_type
```

---

## Enums

### Event Types
```ruby
enum :event_type, {
  conference: 0,
  meetup: 1,
  workshop: 2,
  hackathon: 3,
  webinar: 4,
  networking: 5,
  other: 6,
  talk: 7,
  awards: 8
}, prefix: true
```

### Regions
```ruby
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
```

---

## Routes

```ruby
# Public
root                    "events#index"     # Upcoming events
GET  /past              events#past        # Past events
GET  /events/:id        events#show        # Event detail

# Auth - Email/Password
GET  /login             sessions#new
POST /login             sessions#create
DELETE /logout          sessions#destroy
GET  /signup            registrations#new
POST /signup            registrations#create

# Auth - Google OAuth
GET /auth/google_oauth2/callback    oauth_callbacks#google_oauth2
GET /auth/failure                   oauth_callbacks#failure

# Events (authenticated)
GET    /events/new      events#new
POST   /events          events#create
GET    /events/:id/edit events#edit        # Owner only
PATCH  /events/:id      events#update      # Owner only
DELETE /events/:id      events#destroy     # Owner only

# Health check
GET /up                 -> 200 OK
```

---

## Key Files

```
app/
├── controllers/
│   ├── application_controller.rb      # Authentication concern, helpers
│   ├── events_controller.rb           # CRUD + filters
│   ├── sessions_controller.rb         # Rails 8 auth (generated)
│   ├── registrations_controller.rb    # Email signup
│   └── oauth_callbacks_controller.rb  # Google OAuth
├── models/
│   ├── user.rb                        # has_secure_password, has_many :events
│   ├── session.rb                     # Rails 8 auth (generated)
│   ├── event.rb                       # Enums, scopes, validations
│   └── current.rb                     # Rails 8 Current attributes
├── views/
│   ├── layouts/application.html.erb   # Pico CSS, nav
│   ├── events/
│   │   ├── index.html.erb             # Upcoming events
│   │   ├── past.html.erb              # Past events
│   │   ├── show.html.erb              # Event detail
│   │   ├── new.html.erb / edit.html.erb
│   │   ├── _form.html.erb             # Shared form
│   │   ├── _event_card.html.erb       # List item
│   │   └── _filters.html.erb          # Filter controls
│   ├── sessions/new.html.erb          # Login form
│   └── registrations/new.html.erb     # Signup form
├── helpers/
│   └── events_helper.rb               # CITIES_BY_REGION, options helpers
└── assets/stylesheets/
    └── application.css                # Custom styles, badges
```

---

## Authentication

### Two Methods

1. **Email/Password** (Rails 8 built-in)
   - `has_secure_password` with BCrypt
   - Session-based auth via `Session` model
   - `Current.user` for current user access

2. **Google OAuth** (OmniAuth)
   - Links to existing accounts by email
   - Creates new account if email not found
   - Stores `google_uid` and `avatar_url`

### Key Helpers
```ruby
# In controllers/views
Current.user          # Current logged-in user (or nil)
logged_in?            # Boolean helper

# In controllers
require_login         # Before action, redirects if not logged in
start_new_session_for(user)  # Create session after login/signup
```

### Authorization
```ruby
# Event ownership check
@event.owned_by?(Current.user)  # Returns true if user owns event
```

---

## Event Scopes

```ruby
Event.upcoming          # start_date >= today, ASC order
Event.past              # start_date < today, DESC order
Event.by_region(:auckland)
Event.by_city("Auckland CBD")
Event.by_event_type(:meetup)
```

---

## Cities by Region

Defined in `app/helpers/events_helper.rb`:

```ruby
CITIES_BY_REGION = {
  "auckland" => ["Auckland CBD", "North Shore", "West Auckland", "South Auckland", "East Auckland", "Other"],
  "wellington" => ["Wellington CBD", "Lower Hutt", "Upper Hutt", "Porirua", "Kāpiti Coast", "Other"],
  "canterbury" => ["Christchurch", "Timaru", "Ashburton", "Other"],
  "online" => ["Online"],
  # ... all 17 regions
}
```

Used for:
- Dynamic city dropdown (changes when region selected)
- Filter validation

---

## Environment Variables

```bash
# Required for Google OAuth (optional feature)
GOOGLE_CLIENT_ID=xxx.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=xxx

# Required for production
SECRET_KEY_BASE=xxx   # Generate with: bin/rails secret
RAILS_MASTER_KEY=xxx  # From config/master.key

# Optional
RAILS_ENV=production
```

**Local Development**: Use `dotenv-rails` gem with `.env` file.

---

## Common Commands

```bash
# Development
bin/rails server              # Start server
bin/rails console             # Rails console
bin/rails db:migrate          # Run migrations
bin/rails db:seed             # Seed sample data
bin/rails db:reset            # Drop, create, migrate, seed

# Production prep
bin/rails assets:precompile   # Precompile assets
bin/rails secret              # Generate secret key

# Deployment
kamal setup                   # First-time server setup
kamal deploy                  # Deploy changes
kamal logs                    # View logs
kamal app exec -i 'bin/rails console'  # Production console
```

---

## Styling Notes

### Pico CSS
- Classless framework - HTML elements are styled automatically
- Use semantic HTML (`<article>`, `<header>`, `<nav>`, etc.)
- Forms, buttons, inputs styled by default

### Custom Classes (application.css)
```css
.badge              /* Event type/cost badges */
.badge-conference   /* Purple */
.badge-meetup       /* Green */
.badge-workshop     /* Orange */
.badge-hackathon    /* Red */
.badge-webinar      /* Teal */
.badge-networking   /* Pink */
.badge-talk        /* Green */
.badge-awards      /* Amber */
.badge-free         /* Green */
.badge-paid         /* Blue */
.event-card         /* Event list item */
.event-meta         /* Date/location text */
.filters            /* Filter bar container */
```

---

## Database Files (SQLite)

All in `storage/` folder:
```
storage/
├── development.sqlite3       # Main database
├── development_cache.sqlite3 # Solid Cache
├── development_queue.sqlite3 # Solid Queue
├── production.sqlite3        # (in production)
├── production_cache.sqlite3
└── production_queue.sqlite3
```

**Backup**: Just copy the `.sqlite3` files.

---

## No-Build Verification

Check that the app truly has no Node.js dependencies:

```bash
# These should NOT exist:
ls node_modules     # Should fail: No such file
ls package.json     # Should fail: No such file
ls yarn.lock        # Should fail: No such file

# This SHOULD exist:
cat config/importmap.rb   # JavaScript imports via importmaps
```

---

## Adding New Features

### New Event Field
1. Generate migration: `rails g migration AddXxxToEvents xxx:type`
2. Run migration: `rails db:migrate`
3. Add to `event_params` in `EventsController`
4. Add to `_form.html.erb`
5. Display in `show.html.erb` and `_event_card.html.erb`

### New Region
1. Add to `enum :region` in `Event` model
2. Add cities to `CITIES_BY_REGION` in `EventsHelper`

### New Event Type
1. Add to `enum :event_type` in `Event` model
2. Add CSS class `.badge-newtype` in `application.css`

---

## Gotchas

1. **`email_address` not `email`**: Rails 8 auth generator uses `email_address`
2. **`Current.user` not `current_user`**: Rails 8 uses Current attributes
3. **Enum prefix**: Use `event.event_type_meetup?` not `event.meetup?`
4. **SQLite in production**: Works great for small-medium sites, just backup regularly
5. **No Action Cable**: Skipped to keep simple (add back if needed)
6. **Pico CSS via CDN**: No local copy, requires internet

---

## Deployment Checklist

Before deploying:
- [ ] `RAILS_MASTER_KEY` set in production
- [ ] `SECRET_KEY_BASE` set in production
- [ ] Google OAuth credentials updated for production domain (if using)
- [ ] DNS pointed to server
- [ ] SSL certificate will be auto-generated by Kamal/Traefik

See `plan-deployment.md` for full Kamal setup.
