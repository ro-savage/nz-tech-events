# NZ Tech Events - Testing Guide

Reference for AI agents and developers on running and maintaining the test suite.

## Overview

The test suite uses **Rails Minitest** with **fixtures** for test data. Tests are organized into three categories:

| Category | Path | What it covers |
|----------|------|----------------|
| Model tests | `test/models/` | Validations, scopes, enums, instance methods |
| Request tests | `test/requests/` | Controller actions, routing, auth, HTTP responses |
| Mailer tests | `test/mailers/` | Email delivery, recipients, subjects, body content |

## Running Tests

```bash
# Run the full suite
bin/rails test

# Run a category
bin/rails test test/models/
bin/rails test test/requests/
bin/rails test test/mailers/

# Run a single file
bin/rails test test/models/event_test.rb

# Run a single test by line number
bin/rails test test/models/event_test.rb:42

# Verbose output (show test names)
bin/rails test -v
```

Tests run in parallel by default using all available CPU cores (configured in `test/test_helper.rb`).

## Pre-commit Hook

A git pre-commit hook at `.git/hooks/pre-commit` runs the full test suite before each commit. If any test fails, the commit is blocked.

### Setup

```bash
chmod +x .git/hooks/pre-commit
```

### Bypass

If you need to commit without running tests (e.g., documentation-only change):

```bash
git commit --no-verify
```

## Test Data (Fixtures)

Fixtures live in `test/fixtures/*.yml` and are loaded automatically for all tests.

### Users

| Fixture | Email | Role |
|---------|-------|------|
| `regular` | regular@example.com | Normal user, not an organiser |
| `admin` | admin@example.com | Admin user (`admin: true`) |
| `organiser` | organiser@example.com | Approved organiser (`approved_organiser: true`) |

All users have password: `password123`

### Events

| Fixture | Title | Owner | State |
|---------|-------|-------|-------|
| `approved_upcoming` | Wellington Ruby Meetup | regular | Approved, 7 days from now |
| `unapproved_upcoming` | Startup Hackathon | regular | Not approved, 14 days from now |
| `past_event` | NZ Tech Conference 2025 | regular | Approved, 30 days ago |
| `multi_day_event` | Rails Workshop Weekend | organiser | Approved, multi-day |
| `free_event` | Tech Networking Evening | organiser | Approved, free |
| `paid_event` | AI Conference NZ | organiser | Approved, $50 |

### Email Subscriptions

| Fixture | Email | Region | Token |
|---------|-------|--------|-------|
| `wellington_sub` | subscriber@example.com | Wellington | `test_token_wellington_123abc` |
| `auckland_sub` | auckland_subscriber@example.com | Auckland | `test_token_auckland_456def` |

### Adding New Fixtures

Add entries to the appropriate YAML file in `test/fixtures/`. Use ERB for dynamic values:

```yaml
my_new_event:
  title: "My Event"
  start_date: <%= 10.days.from_now.to_date %>
  event_type: 1
  approved: true
  user: regular
  city: "Auckland CBD"
```

Foreign keys use the fixture name (e.g., `user: regular` references the `regular` user fixture).

## Authentication in Request Tests

The `AuthenticationHelper` module (in `test/support/authentication_helper.rb`) is included in all integration tests.

```ruby
# Sign in as a user
sign_in_as(users(:regular))

# Sign out
sign_out
```

### Testing Authenticated vs Unauthenticated Paths

```ruby
test "unauthenticated user is redirected to login" do
  get new_event_path
  assert_redirected_to new_session_path
end

test "authenticated user can access new event form" do
  sign_in_as(users(:regular))
  get new_event_path
  assert_response :success
end
```

### Testing Authorization (Owner-only Actions)

```ruby
test "non-owner cannot edit event" do
  sign_in_as(users(:organiser))
  event = events(:approved_upcoming)  # owned by :regular
  get edit_event_path(event)
  assert_redirected_to event_path(event)
end
```

## Adding New Tests

### File Naming Convention

- Model tests: `test/models/<model_name>_test.rb`
- Request tests: `test/requests/<controller_name>_test.rb`
- Mailer tests: `test/mailers/<mailer_name>_test.rb`

### Example Model Test

```ruby
require "test_helper"

class EventTest < ActiveSupport::TestCase
  test "event requires a title" do
    event = Event.new(title: nil)
    assert_not event.valid?
    assert_includes event.errors[:title], "can't be blank"
  end
end
```

### Example Request Test

```ruby
require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
  test "index page renders successfully" do
    get root_path
    assert_response :success
    assert_select "h1"
  end
end
```

### Example Mailer Test

```ruby
require "test_helper"

class EventMailerTest < ActionMailer::TestCase
  test "approved email sent to event owner" do
    event = events(:approved_upcoming)
    mail = EventMailer.approved(event)
    assert_equal [event.user.email_address], mail.to
    assert_match event.title, mail.body.encoded
  end
end
```

## What to Test When Making Changes

### Adding a new field to events
1. Update fixtures to include the new field
2. Add model validation tests if the field has validations
3. Add a smoke test that the show and index pages still render (page rendering has broken from schema changes before)

### Adding a new controller action
1. Add request tests for the new action
2. Test both authenticated and unauthenticated access
3. Test authorization if the action is restricted

### Changing a column type or removing a column
This has caused 500 errors in production before. Always:
1. Update all fixtures that reference the changed column
2. Add or update smoke tests that render affected pages
3. Run the full suite to catch any view-level breakage

### Adding a new mailer
1. Create `test/mailers/<mailer_name>_test.rb`
2. Test recipients, subject, and key body content
3. Test edge cases (e.g., empty lists, missing optional fields)

## Test Environment Notes

- **ENABLE_RECAPTCHA** is unset in the test environment, so reCAPTCHA validation is skipped
- **ActionMailer** uses the `:test` delivery method; emails are stored in `ActionMailer::Base.deliveries`
- **Database** is SQLite, same as development but using a separate test database
- **Parallelization** is enabled by default; tests should not depend on shared mutable state

## Debugging Test Failures

### Reading Test Output

A failing test shows:
```
FAIL EventTest#test_event_requires_a_title (0.12s)
  Expected true to be nil or false
  test/models/event_test.rb:10:in `block in <class:EventTest>'
```

- **First line**: test class, test name, and duration
- **Second line**: the assertion that failed
- **Third line**: file and line number

### Running a Single Failing Test

Copy the file path and line number from the failure output:

```bash
bin/rails test test/models/event_test.rb:10
```

### Common Issues

- **Fixture-related errors**: Check that fixture YAML is valid and all referenced associations exist
- **`email_address` not `email`**: Rails 8 auth uses `email_address` as the column name
- **`Current.user` not `current_user`**: This app uses Rails 8 Current attributes
- **Enum access**: Use `event.event_type_meetup?` with the prefix, not `event.meetup?`
