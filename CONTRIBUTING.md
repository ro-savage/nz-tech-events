# Contributing to NZ Tech Events

Welcome, and thanks for your interest in contributing to NZ Tech Events! This project helps the New Zealand tech community discover local events, and contributions of all kinds are appreciated.

## Getting Started

### Prerequisites

- Ruby (see `.ruby-version`)
- Bundler
- SQLite3

### Setup

```bash
git clone <repo>
cd nz-tech-events
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/rails server
# Visit http://localhost:3000
```

For full details on the tech stack and architecture, see the project README.

### No Node.js Policy

This project intentionally has **zero Node.js dependencies**. There is no `package.json`, no `node_modules`, and no build step. JavaScript is managed via [Importmaps](https://github.com/rails/importmap-rails). Please do not introduce Node.js tooling.

## Running Tests

```bash
# Run the full suite
bin/rails test

# Run a specific category
bin/rails test test/models/
bin/rails test test/requests/

# Run a single file
bin/rails test test/models/event_test.rb

# Run a single test by line number
bin/rails test test/models/event_test.rb:42
```

All pull requests must include tests. See `docs/testing.md` for detailed guidance on fixtures, authentication helpers, and test patterns.

## Code Style

- **Framework conventions**: Rails omakase (follow Rails defaults)
- **Indentation**: 2 spaces
- **Quotes**: single quotes for Ruby strings (unless interpolation is needed)
- **Line length**: 80-100 characters
- **CSS**: Pico CSS (classless). Use semantic HTML elements. Custom classes are defined in `app/assets/stylesheets/application.css`.
- **No unused code**: remove dead code, unused imports, and stale feature flags

## Branch Naming

Use a prefix that describes the type of change:

- `feature/` -- new functionality
- `fix/` -- bug fixes
- `chore/` -- maintenance, dependency updates, CI changes
- `docs/` -- documentation only

Example: `feature/add-event-search`, `fix/date-filter-off-by-one`

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add region filter to event list
fix: correct date display for multi-day events
test: add request tests for API token creation
chore: update Rails to 8.0.1
docs: add API authentication examples
```

Keep the subject line under 72 characters. Use the body for additional context when needed.

## Pull Request Process

1. **Branch from `main`**. Keep your branch up to date with `main`.
2. **Write tests** for every new feature and bug fix.
3. **Ensure CI passes** -- linting, type checks, and tests must all be green.
4. **Keep PRs small and focused**. One logical change per PR.
5. **Write a descriptive title and summary**. Explain what changed and why.
6. **Request a review** before merging.

### What Makes a Good PR

- Small, focused scope -- easy to review
- Tests included and passing
- Descriptive title following conventional commit style
- Summary explains the motivation, not just the mechanics
- No unrelated changes mixed in

## Reporting Bugs

Use [GitHub Issues](https://github.com/ro-savage/nz-tech-events/issues) to report bugs. Please include:

- Steps to reproduce the problem
- Expected vs actual behavior
- Browser and OS (if relevant)
- Screenshots or error messages (if available)

## Code of Conduct

Be kind, respectful, and constructive. We are building something for the NZ tech community, and we expect all contributors to treat each other with courtesy. Harassment, discrimination, and disrespectful behavior will not be tolerated.

## Questions?

Open an issue on GitHub or start a discussion. We are happy to help you get started.
