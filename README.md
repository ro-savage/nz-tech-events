# NZ Tech Events

A community-driven listing of technology events across New Zealand. Browse upcoming conferences, meetups, workshops, and more -- filter by region and city, or post your own events.

<!-- TODO: Add CI status badge once PR #15 merges -->

**Live site:** [techevents.co.nz](https://techevents.co.nz)

---

## What is this?

NZ Tech Events helps Kiwi developers and tech enthusiasts find relevant events happening near them. Key features include:

- **Event browsing** with filters for region, city, and event type
- **User accounts** via email/password or Google sign-in
- **Event posting** with an approval workflow (admins approve before events go live)
- **REST API** for programmatic access to event data
- **No-build frontend** -- zero Node.js, no bundler, no build step

---

## Tech Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| Framework | Rails 8 | Full-stack, server-rendered |
| Database | SQLite3 | Single-file, easy backups |
| Cache | Solid Cache | SQLite-backed |
| Queue | Solid Queue | SQLite-backed |
| CSS | Pico CSS (CDN) | Classless framework, no build |
| JavaScript | Importmaps | No bundler, no Node.js |
| Interactivity | Hotwire (Turbo + Stimulus) | SPA-like without the complexity |
| Auth | Rails 8 auth + OmniAuth | Email/password + Google OAuth |
| Markdown | Redcarpet | For API event descriptions |
| Deployment | Kamal 2 | Docker-based, deployed to Hetzner |

**Philosophy:** This app has zero Node.js dependencies. There is no `package.json`, no `node_modules`, and no build step. JavaScript is managed entirely through [importmaps](https://github.com/rails/importmap-rails).

---

## Quick Start

### Prerequisites

- Ruby 3.4+
- SQLite3
- Bundler (`gem install bundler`)

### Setup

```bash
git clone https://github.com/ro-savage/nz-tech-events.git
cd nz-tech-events
bundle install
bin/rails db:prepare
bin/rails db:seed
```

### Run the server

```bash
bin/rails server
# Visit http://localhost:3000
```

### Test credentials (from seed data)

- **Email:** test@example.com
- **Password:** password123

### Environment variables

Copy the example env file and fill in values as needed:

```bash
cp .env.example .env
```

Google OAuth and reCAPTCHA are optional for local development. See `.env.example` for the full list of configurable variables.

### Verify no-build setup

```bash
# These should NOT exist:
ls node_modules     # No such file or directory
ls package.json     # No such file or directory

# This SHOULD exist:
cat config/importmap.rb
```

---

## Running Tests

```bash
# Run all unit and integration tests
bin/rails test
```

Tests run in parallel and typically complete in around 3 seconds. A pre-commit hook also runs the test suite automatically before each commit.

<!-- TODO: Add system test instructions once PR #26 merges -->
<!-- bin/rails test:system  # E2E browser tests -->

---

## Project Structure

```
app/
  controllers/
    events_controller.rb         # Event CRUD and filtering
    sessions_controller.rb       # Login/logout
    registrations_controller.rb  # User signup
    oauth_callbacks_controller.rb # Google OAuth
    api_tokens_controller.rb     # API token management (web UI)
    api/v1/                      # REST API controllers
  models/
    user.rb                      # Accounts, authentication
    event.rb                     # Core model -- enums, scopes, validations
    event_location.rb            # Multi-region support for events
    api_token.rb                 # Bearer token auth for API
  views/
    events/                      # Event pages (index, show, form, etc.)
    api/docs/                    # Human-readable API documentation
  helpers/
    events_helper.rb             # Region/city mappings, form helpers
  services/
    markdown_converter.rb        # Markdown to HTML via Redcarpet
config/
  importmap.rb                   # JavaScript dependency management
  routes.rb                      # All application routes
db/
  schema.rb                      # Current database schema
storage/
  *.sqlite3                      # SQLite database files (gitignored)
```

---

## API

NZ Tech Events provides a REST API at `/api/v1/` for accessing event data.

- **Public endpoints** (no auth required): list upcoming events, view a single event
- **Authenticated endpoints** (bearer token): create, update, and delete your own events
- **Documentation:** Visit [`/api/docs`](https://techevents.co.nz/api/docs) for full endpoint details and examples
- **Machine-readable spec:** Available at `/api/v1/spec.json`

API tokens can be generated from the web UI by approved organisers and admins. Tokens use the format `techevents_` followed by 32 base58 characters.

---

## Deployment

The app is deployed using [Kamal 2](https://kamal-deploy.org) to a Hetzner server.

Required environment variables for production:

| Variable | Description |
|----------|-------------|
| `SECRET_KEY_BASE` | Generate with `bin/rails secret` |
| `RAILS_MASTER_KEY` | From `config/master.key` |
| `GOOGLE_CLIENT_ID` | Google OAuth (optional) |
| `GOOGLE_CLIENT_SECRET` | Google OAuth (optional) |

```bash
kamal setup    # First-time server setup
kamal deploy   # Deploy changes
kamal logs     # View production logs
```

---

## Contributing

Contributions are welcome. Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

If you find a bug or have a feature request, [open an issue](https://github.com/ro-savage/nz-tech-events/issues).

---

## License

See [LICENSE](LICENSE) for details.
