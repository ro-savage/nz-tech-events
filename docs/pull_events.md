# Event Data Pipeline: Google Sheet → CSV → API

How to pull NZ tech events from the community "Events in Aotearoa" Google Sheet, match them against what's already on techevents.co.nz, enrich them with researched descriptions, and upload the new ones to the live API.

> This document is duplicated as the "Event Data Pipeline" section of `CLAUDE.md` — if you change one, update the other.

**Weekly shortcut:** run `/pull-events-sheets` in Claude Code to do all five steps end to end, including the live upload. The command lives in `.claude/commands/pull-events-sheets.md` (gitignored, so it's local to this machine) and adds the lessons from past runs on top of the steps below.

All data lives in `data/` (gitignored, local-only):

| File | What it is |
|------|------------|
| `data/events.csv` | Master working file — every sheet event, its enrichment, and its `TechEventsID` once matched/uploaded. The only record of sheet↔site matching. |
| `data/techevents.csv` | Mirror of live API events that have **no** sheet counterpart yet (refreshed by step 2). |
| `data/batch_*.json` | Temporary AI-enrichment output consumed by the merge script (step 4). Delete after merging. |

Run the steps in order. Steps 3 and 4 are **AI agent steps** — they require judgment and web research, not just running a script.

## 1. Pull new events from the Google Sheet

```bash
ruby scripts/pull_events.rb
```

Fetches the current and future monthly tabs of the sheet, dedupes against the CSV by title + start_date, and appends only new rows (blank `TechEventsID`, `ai_updated=false`). Existing rows are never modified.

- Tab GIDs are hardcoded in `SheetFetcher::TABS` in `scripts/pull_events.rb` — add new tabs by hand as the sheet grows (GIDs are in the sheet's public `htmlview` page source).
- The sheet also keeps a whole-year tab (e.g. "2027") for events beyond the monthly tabs. It's listed with `month: nil`: the month is read from the date text, and rows whose date has no month are skipped with a warning (adding them would duplicate them on every run).
- Safe to re-run any time; re-runs report "0 new" for unchanged tabs.

## 2. Pull existing events from the TechEvents API

```bash
ruby scripts/pull_techevents.rb
```

Fetches all events (upcoming + past) from the live API into `data/techevents.csv`, excluding events whose id already appears as a `TechEventsID` in `events.csv`.

## 3. AI agent step — fuzzy-match sheet events to API events

For every `events.csv` row with a blank `TechEventsID`, check whether the event already exists on the site (i.e. in `techevents.csv`).

**Matching MUST be fuzzy** — the same event can be named differently in the two sources (e.g. sheet "BizFest 2026" vs site "BizFest 2026: Build Your Village"). Compare:

- title similarity (substring/partial matches count)
- `start_date` and region
- `registration_url` — an identical URL means it's the same event, regardless of title

For each confirmed match, write the API id into the row's `TechEventsID`, then re-run `ruby scripts/pull_techevents.rb` to keep `techevents.csv` consistent.

This is the duplicate-prevention step: only rows still blank afterwards get uploaded in step 5.

## 4. AI agent step — research each new event and write a description

For every remaining row with blank `TechEventsID` and `ai_updated` ≠ `true`:

- **Recurring events** (same title as an already-enriched row): reuse that row's `event_type` and `ai_description`.
- **New events**: research each one by fetching its `registration_url` (fall back to web search). Use only facts from the sheet and fetched pages — never invent speakers, prices, or venues. Write a two-paragraph plain-text description (para 1: what the event is and what happens there; para 2: logistics and who it's for) and pick an `event_type` from the Event enum (`conference`, `meetup`, `workshop`, `hackathon`, `webinar`, `networking`, `other`, `talk`, `awards`). Parallel subagents work well (~8 events each).
- Write results to `data/batch_*.json` files shaped:

  ```json
  [{"row": 81, "event_type": "webinar", "ai_description": "..."}]
  ```

  where `row` is the **1-based data-row number** in `events.csv` (first data row after the header = 1). Then run:

  ```bash
  ruby scripts/merge_batch_results.rb
  ```

  The merge sets `ai_updated=true` and skips rows already enriched, so it's safe to re-run. Delete the batch files after merging.
- **Copy `ai_description` → `description_markdown`** for the upload candidates — the uploader sends `description_markdown`, and the API rejects events without a description.
- Report data-quality issues found while researching (wrong dates, stale blurbs, malformed URLs, past events) and fix verified ones in the CSV — except titles (see gotchas).

## 5. Upload new events to the live API

```bash
TECHEVENTS_API_URL=https://techevents.co.nz/api/v1 TECHEVENTS_API_TOKEN=<token> ruby scripts/upload_events.rb
```

- **Token**: create at techevents.co.nz `/api_tokens` (requires an approved-organiser or admin account); format is `techevents_` + 32 base58 chars. Verify it before bulk-posting:

  ```bash
  curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer <token>" \
    https://techevents.co.nz/api/v1/events/mine   # expect 200
  ```

- **Without `TECHEVENTS_API_URL` the script posts to localhost:3000** — useful as a dry run against a dev server, wrong for a live upload.
- Uploads every row with a blank `TechEventsID`, writes returned ids back into the CSV as it goes (safe to re-run after partial failure — uploaded rows are skipped), sleeps 2s between requests for the write rate limit, and logs failures to `data/events_errors.csv`.
- Events created by approved-organiser tokens are **auto-approved** — they're live on the site immediately.
- Re-run `ruby scripts/pull_techevents.rb` afterwards to re-sync.

## Pipeline gotchas

- **Never edit a sheet-sourced title in `events.csv`** — the dedup key is title + start_date, so an edited title comes back as a duplicate row on the next pull. Fix bad titles on the live site instead:

  ```bash
  curl -X PATCH https://techevents.co.nz/api/v1/events/<id> \
    -H "Authorization: Bearer <token>" -H "Content-Type: application/json" \
    -d '{"event":{"title":"Corrected Title"}}'
  ```

- `TechEventsID` = `SKIP` means the event was deliberately held back (postponed, cancelled, or dead link); the reason and date checked are in `notes`. The uploader skips any non-blank ID — clear `SKIP` to upload it later.
- `data/` is gitignored: `events.csv` is the only record of sheet↔site matching. Back it up before risky operations.
- `config/event_sources.yml` lists the organiser pages that site events came from (Humanitix hosts, Meetup groups, Luma calendars, Eventbrite organisers, organisers' own `/events` pages), with tested JSON feeds where one exists. Add an entry when events start arriving from a new organiser.
- `/pull-events-websites` (`.claude/commands/pull-events-websites.md`, local like `/pull-events-sheets`) checks those pages at most once a week and uploads new events: recurring events up to 3 months ahead, and one-off events at any future date once the organiser has set the actual day. It keeps its rows in `data/source_events.csv` (never `events.csv`, so the sheet pipeline sees them as existing site events), logs each run to `data/source_checks.csv`, dedupes against `data/techevents_all.csv` from `ruby scripts/dump_techevents.rb` (every live event, unlike `techevents.csv`), and uploads with `EVENTS_CSV=data/source_events.csv ruby scripts/upload_events.rb`.
- Tests for the pipeline scripts live in `test/scripts/` and run standalone: `ruby test/scripts/pull_events_test.rb` and `ruby test/scripts/upload_events_test.rb`.
