# NZ Tech Events - Project Plan

## Overview

A simple, clean website for listing tech events in New Zealand. Users can browse upcoming events, filter by location, and registered users can post and manage their own events.

**Key Principles:**
- No-build (zero Node.js)
- SQLite for everything
- Simple to deploy and maintain
- Easy for future AI agents to modify

---

## Tech Stack

| Layer | Technology | Why |
|-------|------------|-----|
| Framework | Rails 8.0 | Full-stack, batteries included |
| Database | SQLite3 | Simple, single file, easy backups |
| Cache | Solid Cache | SQLite-backed, no Redis needed |
| Queue | Solid Queue | SQLite-backed, no Redis needed |
| CSS | Pico CSS (CDN) | Classless, beautiful defaults, no build |
| JavaScript | Importmaps | No bundler, no Node.js |
| Interactivity | Hotwire (Turbo + Stimulus) | SPA-like feel, Rails default |
| Auth | Rails 8 Generator + OmniAuth | Email/password + Google OAuth |
| Deployment | Kamal 2 | Docker-based, to Hetzner Cloud |

---

## Authentication

**Two sign-in methods:**

1. **Email/Password** - Rails 8 built-in authentication generator
   - `has_secure_password` with BCrypt
   - Session-based with `Session` model
   - Password reset flow included

2. **Google OAuth** - OmniAuth gem
   - Links to existing accounts by email
   - Creates new account if not found
   - Optional (site works without it)

---

## Data Models

### User
| Field | Type | Notes |
|-------|------|-------|
| id | integer | Primary key |
| email_address | string | Unique, required (Rails 8 convention) |
| password_digest | string | BCrypt hash |
| name | string | Optional for email users |
| google_uid | string | Unique, for OAuth |
| avatar_url | string | From Google |

### Event
| Field | Type | Notes |
|-------|------|-------|
| id | integer | Primary key |
| title | string | Required, max 200 chars |
| description | text | Required |
| start_date | date | Required |
| end_date | date | Optional (multi-day events) |
| start_time | time | Optional |
| end_time | time | Optional |
| cost | string | Free-form ("Free", "$50", etc.) |
| event_type | integer | Enum (conference, meetup, etc.) |
| registration_url | string | Optional external link |
| region | integer | Enum (NZ regions) |
| city | string | Required |
| address | text | Optional venue details |
| user_id | FK | Owner of event |

---

## Event Types

| Type | Badge Color |
|------|-------------|
| Conference | Purple |
| Meetup | Green |
| Workshop | Orange |
| Hackathon | Red |
| Webinar | Teal |
| Networking | Pink |
| Other | Gray |

---

## NZ Regions

- Northland
- Auckland
- Waikato
- Bay of Plenty
- Gisborne
- Hawke's Bay
- Taranaki
- Manawatū-Whanganui
- Wellington
- Tasman
- Nelson
- Marlborough
- West Coast
- Canterbury
- Otago
- Southland
- Online (virtual events)

---

## Pages

| Page | Route | Description |
|------|-------|-------------|
| Home | `/` | Upcoming events with filters |
| Past Events | `/past` | Past events, most recent first |
| Event Detail | `/events/:id` | Full event info |
| New Event | `/events/new` | Create event (logged in) |
| Edit Event | `/events/:id/edit` | Edit own event |
| Login | `/login` | Email/password + Google |
| Sign Up | `/signup` | Create account |

---

## Features

### MVP (Phase 1)
- [x] Browse upcoming events (no login required)
- [x] Filter by region, city, event type
- [x] View past events
- [x] Sign up with email/password
- [x] Sign in with Google (optional)
- [x] Create events (logged in)
- [x] Edit/delete own events
- [x] Single column, mobile-first layout
- [x] Deploy to Hetzner with Kamal

### Polish (Phase 2)
- [ ] Date range filtering
- [ ] Event search
- [ ] SEO meta tags
- [ ] Open Graph images
- [ ] Analytics (Plausible/Umami)

### Future (Phase 3)
- [ ] iCal export
- [ ] Email notifications
- [ ] Event duplication
- [ ] Admin moderation

---

## UI Design

### Philosophy
- Clean, minimal, professional
- Mobile-first responsive
- Fast load times
- Accessible (WCAG AA)

### Layout
- Single column, max 800px
- Pico CSS for base styling
- Custom badges for event types
- Simple filter bar at top

### Colors
- Primary: Blue (#2563eb)
- Event type badges: Various colors
- Free badge: Green
- Paid badge: Blue

See `plan-design.md` for detailed design specs.

---

## Deployment

| Component | Choice | Cost |
|-----------|--------|------|
| Server | Hetzner CX22 | ~€5/month |
| Registry | GitHub Container Registry | Free |
| SSL | Let's Encrypt | Free |
| Domain | .co.nz | ~$25/year |
| **Total** | | **~$9 NZD/month** |

See `plan-deployment.md` for step-by-step deployment guide.

---

## File Structure

```
tech-events-rails/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   ├── events_controller.rb
│   │   ├── sessions_controller.rb
│   │   ├── registrations_controller.rb
│   │   └── oauth_callbacks_controller.rb
│   ├── models/
│   │   ├── user.rb
│   │   ├── session.rb
│   │   ├── event.rb
│   │   └── current.rb
│   ├── views/
│   │   ├── layouts/application.html.erb
│   │   ├── events/
│   │   ├── sessions/
│   │   └── registrations/
│   ├── helpers/
│   │   └── events_helper.rb
│   └── assets/stylesheets/
│       └── application.css
├── config/
│   ├── routes.rb
│   ├── database.yml
│   ├── deploy.yml (Kamal)
│   └── initializers/
│       └── omniauth.rb
├── db/
│   ├── migrate/
│   └── seeds.rb
├── storage/
│   ├── development.sqlite3
│   ├── development_cache.sqlite3
│   └── development_queue.sqlite3
├── Dockerfile
├── .dockerignore
├── Gemfile
└── CLAUDE.md
```

---

## Related Documents

| Document | Purpose |
|----------|---------|
| `plan-implementation.md` | Step-by-step build guide |
| `plan-design.md` | UI/UX specifications |
| `plan-deployment.md` | Hetzner + Kamal setup |
| `CLAUDE.md` | Quick reference for AI agents |

---

## Success Criteria

- [ ] Users can browse upcoming events without logging in
- [ ] Users can filter by region, city, and type
- [ ] Users can view past events
- [ ] Users can sign up with email or Google
- [ ] Logged-in users can create events
- [ ] Users can only edit/delete their own events
- [ ] Site looks clean and professional
- [ ] Site loads fast (<2s)
- [ ] Site is mobile responsive
- [ ] Deployed and running on Hetzner
- [ ] SSL certificate working
- [ ] No Node.js in production
