# CSV Upload Script Design

Upload events from `data/events.csv` to the TechEvents API via `POST /api/v1/events`.

## API Change

Add `:source` and `:source_url` to `api_event_params` in `Api::V1::EventsController`.

## Script: `scripts/upload_events.rb`

### Behaviour

1. Read `data/events.csv` (Ruby CSV with headers, handles multiline fields).
2. Skip rows where `TechEventsID` is non-empty (already uploaded).
3. For each remaining row:
   - Build JSON body mapping CSV columns to API fields.
   - POST to `{base_url}/events` with bearer token.
   - On 201: store returned `id` as the row's `TechEventsID`.
   - On error (422, 401, 5xx, network): record the error message for that row.
   - Sleep 2 seconds between requests to stay under 30 writes/min rate limit.
4. Overwrite `data/events.csv` with all rows, now including any new TechEventsIDs.
5. If any errors occurred, write `data/events_errors.csv` containing only failed rows, with an `error` column prepended.

### Field Mapping

| CSV Column | API Field | Notes |
|---|---|---|
| `title` | `event.title` | |
| `short_summary` | `event.short_summary` | |
| `description_markdowndescription_markdown` | `event.description_markdown` | Typo in CSV header |
| `start_date` | `event.start_date` | |
| `end_date` | `event.end_date` | |
| `start_time` | `event.start_time` | |
| `end_time` | `event.end_time` | |
| `cost` | `event.cost` | |
| `event_type` | `event.event_type` | |
| `registration_url` | `event.registration_url` | |
| `address` | `event.address` | |
| `source` | `event.source` | Requires API change |
| `source_url` | `event.source_url` | Requires API change |
| `region` + `city` | `event.locations[0]` | Single location object `{region, city}` |

**Not sent to API** (preserved in CSV only): `organiser`, `event_mode`, `notes`, `ai_description`, `ai_updated`.

### Configuration

- `TECHEVENTS_API_URL` env var, defaults to `http://localhost:3000/api/v1`
- `TECHEVENTS_API_TOKEN` env var, required

### Output

- Progress printed to stdout: row number, title, success/error.
- Summary at end: total, uploaded, skipped, errors.
