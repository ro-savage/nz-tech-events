# Google Sheet Event Puller - Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a re-runnable Ruby script that pulls NZ tech events from a public Google Sheet into a local CSV, deduplicating on re-runs, with placeholder fields for AI enrichment and eventual API upload.

**Architecture:** Standalone Ruby script using only stdlib (`csv`, `open-uri`, `date`, `time`). Fetches each monthly tab via Google Sheets' public CSV export URL, parses human-readable dates and region names, deduplicates against an existing CSV by title + start_date, and appends only new events. Includes `ai_description` and `ai_updated` columns for a future AI enrichment pass.

**Tech Stack:** Ruby stdlib only (no gems, no Rails dependency)

---

## File Structure

| Action | File | Responsibility |
|--------|------|---------------|
| Create | `scripts/pull_events.rb` | Main script - all logic in one file, runnable with `ruby scripts/pull_events.rb` |
| Create | `test/scripts/pull_events_test.rb` | Unit tests for date parsing, region mapping, and dedup logic |
| Create | `data/.gitkeep` | Ensure `data/` directory is tracked |
| Output | `data/events.csv` | Generated CSV (created by script at runtime) |

---

## CSV Output Columns

These columns align with the TechEvents API fields plus extra columns for sheet data and AI enrichment:

| Column | Source | Notes |
|--------|--------|-------|
| `TechEventsID` | blank | Filled in after API upload |
| `title` | Sheet: "Event title" | |
| `short_summary` | Sheet: "Blurb" | |
| `description_markdown` | blank | For manual entry or AI-generated content |
| `start_date` | Parsed from "Date and time" | ISO 8601: `2026-03-02` |
| `end_date` | Parsed from "Date and time" | Only for multi-day: `9-11 March` |
| `start_time` | Parsed from "Date and time" | 24hr: `17:30` |
| `end_time` | blank | Sheet doesn't provide this |
| `cost` | blank | Sheet doesn't provide this |
| `event_type` | blank | Sheet doesn't classify events |
| `registration_url` | Sheet: "Tickets link" | |
| `region` | Mapped from Sheet: "Region" | TechEvents enum value: `auckland`, `wellington`, etc. |
| `city` | Inferred from region/venue | |
| `address` | Sheet: "Venue" | |
| `source` | `"Events in Aotearoa"` | Fixed string identifying the sheet |
| `source_url` | Link to the specific sheet tab | |
| `organiser` | Sheet: "Organiser details" | Extra column, not in API |
| `event_mode` | Sheet: "In person/Online/Hybrid" | Extra column, not in API |
| `notes` | Sheet: "Notes" | Extra column, not in API |
| `ai_description` | blank | For AI enrichment pass |
| `ai_updated` | `false` | Set to `true` after AI enrichment |

---

## Google Sheet Details

**Spreadsheet ID:** `1MpH9z4vZnHhYdvmMIYQyht69H4krUye9mEWSXmn81as`

**CSV export URL pattern:** `https://docs.google.com/spreadsheets/d/{ID}/gviz/tq?tqx=out:csv&gid={GID}`

**Tabs (2026):**

| Tab | GID | Month/Year |
|-----|-----|-----------|
| Mar 2026 | 1867800062 | 2026-03 |
| Apr 2026 | 271523334 | 2026-04 |
| May 2026 | 760676255 | 2026-05 |
| Jun 2026 | 1315642224 | 2026-06 |
| Jul 2026 | 2102391099 | 2026-07 |
| Aug 2026 | 475021715 | 2026-08 |
| Sep 2026 | 1287540686 | 2026-09 |
| Oct 2026 | 559745448 | 2026-10 |
| Nov 2026 | 484297661 | 2026-11 |
| Dec 2026 | 1972914618 | 2026-12 |

**Sheet columns (consistent across 2026 tabs):**
1. Date and time
2. Region
3. Event title
4. Blurb (keep it short and sweet)
5. In person/Online/Hybrid
6. Organiser details
7. Venue
8. Tickets link
9. Notes

**Date formats in sheet:**
- `Mon 2nd Mar, 5:30pm` - weekday, ordinal day, month, time
- `9-11 March` - date range (multi-day, no time)
- `Wed 11th March` - weekday, ordinal day, full month, no time
- `18th Mar, 12pm` - ordinal day, month, time (no weekday)
- `20-22 March` - date range
- `Tue 17th Mar, 10am` - standard with time

**Region names in sheet and their enum mappings:**
- `Tāmaki Makaurau/Auckland` → `auckland`
- `Te Whanganui-a-Tara/Wellington` → `wellington`
- `Otautahi/Christchurch` → `canterbury`
- `Aotearoa New Zealand` → `online`
- `Tauranga` → `bay_of_plenty`
- `Kapiti` → `wellington`
- `Waikato/Hamilton` → `waikato`
- `Tāhuna/Queenstown` → `otago`
- `Taupō` → `waikato`
- `Waihōpai/Invercargill` → `southland`

---

## Task 1: Create test file with date parser and region mapper tests

**Files:**
- Create: `test/scripts/pull_events_test.rb`

- [ ] **Step 1: Write failing tests for date parsing**

```ruby
# test/scripts/pull_events_test.rb
require "minitest/autorun"
require "date"
require "time"

# Load the module under test
require_relative "../../scripts/pull_events"

class DateParserTest < Minitest::Test
  # Standard format: "Mon 2nd Mar, 5:30pm"
  def test_weekday_ordinal_month_time
    result = SheetDateParser.parse("Mon 2nd Mar, 5:30pm", 2026, 3)
    assert_equal Date.new(2026, 3, 2), result[:start_date]
    assert_equal "17:30", result[:start_time]
    assert_nil result[:end_date]
  end

  # Time with am: "Tue 3rd Mar, 10am"
  def test_weekday_ordinal_month_am_time
    result = SheetDateParser.parse("Tue 3rd Mar, 10am", 2026, 3)
    assert_equal Date.new(2026, 3, 3), result[:start_date]
    assert_equal "10:00", result[:start_time]
  end

  # Date range: "9-11 March"
  def test_date_range
    result = SheetDateParser.parse("9-11 March", 2026, 3)
    assert_equal Date.new(2026, 3, 9), result[:start_date]
    assert_equal Date.new(2026, 3, 11), result[:end_date]
    assert_nil result[:start_time]
  end

  # Day only with full month: "Wed 11th March"
  def test_weekday_ordinal_full_month_no_time
    result = SheetDateParser.parse("Wed 11th March", 2026, 3)
    assert_equal Date.new(2026, 3, 11), result[:start_date]
    assert_nil result[:start_time]
  end

  # No weekday, ordinal + abbreviated month + time: "18th Mar, 12pm"
  def test_ordinal_month_time_no_weekday
    result = SheetDateParser.parse("18th Mar, 12pm", 2026, 3)
    assert_equal Date.new(2026, 3, 18), result[:start_date]
    assert_equal "12:00", result[:start_time]
  end

  # Date range abbreviated: "11-12 Mar"
  def test_date_range_abbreviated_month
    result = SheetDateParser.parse("11-12 Mar", 2026, 3)
    assert_equal Date.new(2026, 3, 11), result[:start_date]
    assert_equal Date.new(2026, 3, 12), result[:end_date]
  end

  # 12pm should be 12:00 not 00:00
  def test_12pm_is_noon
    result = SheetDateParser.parse("Fri 13th Mar, 12pm", 2026, 3)
    assert_equal "12:00", result[:start_time]
  end

  # 12am should be 00:00
  def test_12am_is_midnight
    result = SheetDateParser.parse("Fri 13th Mar, 12am", 2026, 3)
    assert_equal "00:00", result[:start_time]
  end

  # Time with minutes: "5:30pm"
  def test_time_with_minutes
    result = SheetDateParser.parse("Mon 2nd Mar, 5:30pm", 2026, 3)
    assert_equal "17:30", result[:start_time]
  end

  # Full month name in April tab
  def test_april_date
    result = SheetDateParser.parse("Mon 6th Apr, 5:30pm", 2026, 4)
    assert_equal Date.new(2026, 4, 6), result[:start_date]
    assert_equal "17:30", result[:start_time]
  end

  # Graceful handling of unparseable dates
  def test_unparseable_returns_nil_date
    result = SheetDateParser.parse("TBD", 2026, 3)
    assert_nil result[:start_date]
  end

  # Blank input
  def test_blank_returns_nil
    result = SheetDateParser.parse("", 2026, 3)
    assert_nil result[:start_date]
  end

  # "18th March" - no weekday, full month, no time
  def test_ordinal_full_month_no_time
    result = SheetDateParser.parse("18th March", 2026, 3)
    assert_equal Date.new(2026, 3, 18), result[:start_date]
    assert_nil result[:start_time]
  end
end

class RegionMapperTest < Minitest::Test
  def test_auckland
    assert_equal "auckland", SheetRegionMapper.map("Tāmaki Makaurau/Auckland")
  end

  def test_wellington
    assert_equal "wellington", SheetRegionMapper.map("Te Whanganui-a-Tara/Wellington")
  end

  def test_christchurch_maps_to_canterbury
    assert_equal "canterbury", SheetRegionMapper.map("Otautahi/Christchurch")
  end

  def test_aotearoa_maps_to_online
    assert_equal "online", SheetRegionMapper.map("Aotearoa New Zealand")
  end

  def test_tauranga_maps_to_bay_of_plenty
    assert_equal "bay_of_plenty", SheetRegionMapper.map("Tauranga")
  end

  def test_kapiti_maps_to_wellington
    assert_equal "wellington", SheetRegionMapper.map("Kapiti")
  end

  def test_waikato
    assert_equal "waikato", SheetRegionMapper.map("Waikato/Hamilton")
  end

  def test_queenstown_maps_to_otago
    assert_equal "otago", SheetRegionMapper.map("Tāhuna/Queenstown")
  end

  def test_taupo_maps_to_waikato
    assert_equal "waikato", SheetRegionMapper.map("Taupō")
  end

  def test_invercargill_maps_to_southland
    assert_equal "southland", SheetRegionMapper.map("Waihōpai/Invercargill")
  end

  def test_blank_returns_nil
    assert_nil SheetRegionMapper.map("")
  end

  def test_nil_returns_nil
    assert_nil SheetRegionMapper.map(nil)
  end

  def test_unknown_region_returns_nil
    assert_nil SheetRegionMapper.map("Mars")
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `ruby test/scripts/pull_events_test.rb`
Expected: Errors loading `scripts/pull_events` (file doesn't exist yet)

---

## Task 2: Implement date parser and region mapper

**Files:**
- Create: `scripts/pull_events.rb` (initial version with parser + mapper modules)

- [ ] **Step 1: Implement SheetDateParser module**

```ruby
# scripts/pull_events.rb

require "csv"
require "open-uri"
require "date"
require "time"
require "net/http"

module SheetDateParser
  MONTHS = {
    "jan" => 1, "january" => 1,
    "feb" => 2, "february" => 2,
    "mar" => 3, "march" => 3,
    "apr" => 4, "april" => 4,
    "may" => 5,
    "jun" => 6, "june" => 6,
    "jul" => 7, "july" => 7,
    "aug" => 8, "august" => 8,
    "sep" => 9, "september" => 9,
    "oct" => 10, "october" => 10,
    "nov" => 11, "november" => 11,
    "dec" => 12, "december" => 12
  }.freeze

  # Parse a human-readable date string from the Google Sheet.
  # Returns { start_date: Date|nil, end_date: Date|nil, start_time: String|nil }
  def self.parse(raw, tab_year, tab_month)
    result = { start_date: nil, end_date: nil, start_time: nil }
    return result if raw.nil? || raw.strip.empty?

    text = raw.strip

    # Extract time if present (e.g., "5:30pm", "10am", "12pm")
    time_match = text.match(/(\d{1,2})(?::(\d{2}))?\s*(am|pm)/i)
    if time_match
      hour = time_match[1].to_i
      minutes = (time_match[2] || "00").to_i
      ampm = time_match[3].downcase

      if ampm == "pm" && hour != 12
        hour += 12
      elsif ampm == "am" && hour == 12
        hour = 0
      end

      result[:start_time] = format("%02d:%02d", hour, minutes)
    end

    # Try to find month in the text
    month_num = nil
    MONTHS.each do |name, num|
      if text.downcase.include?(name)
        month_num = num
        break
      end
    end
    month_num ||= tab_month

    # Try date range pattern: "9-11 March" or "11-12 Mar"
    range_match = text.match(/(\d{1,2})\s*[-–]\s*(\d{1,2})\s+/i)
    if range_match
      start_day = range_match[1].to_i
      end_day = range_match[2].to_i
      result[:start_date] = Date.new(tab_year, month_num, start_day)
      result[:end_date] = Date.new(tab_year, month_num, end_day)
      return result
    end

    # Try single date pattern: "2nd", "11th", "18th" etc.
    day_match = text.match(/(\d{1,2})(?:st|nd|rd|th)/i)
    if day_match
      day = day_match[1].to_i
      result[:start_date] = Date.new(tab_year, month_num, day)
      return result
    end

    result
  end
end
```

- [ ] **Step 2: Implement SheetRegionMapper module**

Append to `scripts/pull_events.rb`:

```ruby
module SheetRegionMapper
  # Maps sheet region strings to TechEvents enum values.
  # Matches by keyword - order matters (more specific first).
  MAPPINGS = [
    [/auckland/i, "auckland"],
    [/wellington/i, "wellington"],
    [/christchurch/i, "canterbury"],
    [/canterbury/i, "canterbury"],
    [/tauranga/i, "bay_of_plenty"],
    [/bay.of.plenty/i, "bay_of_plenty"],
    [/rotorua/i, "bay_of_plenty"],
    [/hamilton/i, "waikato"],
    [/waikato/i, "waikato"],
    [/taup/i, "waikato"],
    [/queenstown/i, "otago"],
    [/dunedin/i, "otago"],
    [/otago/i, "otago"],
    [/invercargill/i, "southland"],
    [/southland/i, "southland"],
    [/kapiti/i, "wellington"],
    [/nelson/i, "nelson"],
    [/napier|hastings|hawke/i, "hawkes_bay"],
    [/palmerston|manawat|whanganui/i, "manawatu_whanganui"],
    [/new.plymouth|taranaki/i, "taranaki"],
    [/northland|whang.rei/i, "northland"],
    [/marlborough|blenheim/i, "marlborough"],
    [/tasman|richmond|motueka/i, "tasman"],
    [/west.coast|greymouth|hokitika/i, "west_coast"],
    [/aotearoa|new.zealand|online|virtual|zoom/i, "online"],
  ].freeze

  def self.map(raw)
    return nil if raw.nil? || raw.strip.empty?
    text = raw.strip

    MAPPINGS.each do |pattern, region|
      return region if text.match?(pattern)
    end

    nil
  end
end
```

- [ ] **Step 3: Run tests to verify they pass**

Run: `ruby test/scripts/pull_events_test.rb`
Expected: All tests PASS

---

## Task 3: Implement sheet fetcher and CSV manager

**Files:**
- Modify: `scripts/pull_events.rb`

- [ ] **Step 1: Add tab configuration and fetcher**

Append to `scripts/pull_events.rb`:

```ruby
module SheetFetcher
  SPREADSHEET_ID = "1MpH9z4vZnHhYdvmMIYQyht69H4krUye9mEWSXmn81as"

  TABS = [
    { name: "Mar 2026", gid: "1867800062", year: 2026, month: 3 },
    { name: "Apr 2026", gid: "271523334", year: 2026, month: 4 },
    { name: "May 2026", gid: "760676255", year: 2026, month: 5 },
    { name: "Jun 2026", gid: "1315642224", year: 2026, month: 6 },
    { name: "Jul 2026", gid: "2102391099", year: 2026, month: 7 },
    { name: "Aug 2026", gid: "475021715", year: 2026, month: 8 },
    { name: "Sep 2026", gid: "1287540686", year: 2026, month: 9 },
    { name: "Oct 2026", gid: "559745448", year: 2026, month: 10 },
    { name: "Nov 2026", gid: "484297661", year: 2026, month: 11 },
    { name: "Dec 2026", gid: "1972914618", year: 2026, month: 12 },
  ].freeze

  # Returns tabs from current month onward
  def self.tabs_to_fetch
    today = Date.today
    TABS.select { |tab| Date.new(tab[:year], tab[:month], 1) >= Date.new(today.year, today.month, 1) }
  end

  # Fetch CSV data for a single tab. Returns array of hashes (one per row).
  def self.fetch_tab(tab)
    url = "https://docs.google.com/spreadsheets/d/#{SPREADSHEET_ID}/gviz/tq?tqx=out:csv&gid=#{tab[:gid]}"
    csv_data = URI.open(url, "User-Agent" => "TechEvents-Puller/1.0").read

    rows = CSV.parse(csv_data, headers: true)
    rows.map do |row|
      {
        date_raw: row["Date and time"]&.strip,
        region_raw: row["Region"]&.strip,
        title: row["Event title"]&.strip,
        blurb: row["Blurb (keep it short and sweet)"]&.strip,
        event_mode: row["In person/Online/Hybrid"]&.strip,
        organiser: row["Organiser details"]&.strip,
        venue: row["Venue"]&.strip,
        tickets_link: row["Tickets link"]&.strip,
        notes: row["Notes"]&.strip,
        tab_year: tab[:year],
        tab_month: tab[:month],
        tab_name: tab[:name],
        tab_gid: tab[:gid]
      }
    end.reject { |r| r[:title].nil? || r[:title].empty? }
  end
end
```

- [ ] **Step 2: Add CSV output columns and event builder**

Append to `scripts/pull_events.rb`:

```ruby
module EventBuilder
  CSV_HEADERS = %w[
    TechEventsID
    title
    short_summary
    description_markdown
    start_date
    end_date
    start_time
    end_time
    cost
    event_type
    registration_url
    region
    city
    address
    source
    source_url
    organiser
    event_mode
    notes
    ai_description
    ai_updated
  ].freeze

  SPREADSHEET_URL = "https://docs.google.com/spreadsheets/d/#{SheetFetcher::SPREADSHEET_ID}/edit?gid="

  # Convert a raw sheet row hash into a CSV-ready hash
  def self.build(row)
    parsed_date = SheetDateParser.parse(row[:date_raw], row[:tab_year], row[:tab_month])
    region = SheetRegionMapper.map(row[:region_raw])
    city = infer_city(row[:region_raw], row[:venue], region)

    {
      "TechEventsID" => "",
      "title" => row[:title],
      "short_summary" => row[:blurb],
      "description_markdown" => "",
      "start_date" => parsed_date[:start_date]&.iso8601,
      "end_date" => parsed_date[:end_date]&.iso8601,
      "start_time" => parsed_date[:start_time],
      "end_time" => "",
      "cost" => "",
      "event_type" => "",
      "registration_url" => row[:tickets_link],
      "region" => region,
      "city" => city,
      "address" => row[:venue],
      "source" => "Events in Aotearoa",
      "source_url" => "#{SPREADSHEET_URL}#{row[:tab_gid]}",
      "organiser" => row[:organiser],
      "event_mode" => row[:event_mode],
      "notes" => row[:notes],
      "ai_description" => "",
      "ai_updated" => "false"
    }
  end

  # Best-effort city inference from region text and venue
  def self.infer_city(region_raw, venue, mapped_region)
    return nil if region_raw.nil?

    text = region_raw.strip

    # Direct city mentions in the region field
    return "Auckland CBD" if text =~ /auckland/i && mapped_region == "auckland"
    return "Wellington CBD" if text =~ /wellington/i && mapped_region == "wellington"
    return "Christchurch" if text =~ /christchurch/i
    return "Tauranga" if text =~ /tauranga/i
    return "Hamilton" if text =~ /hamilton/i
    return "Queenstown" if text =~ /queenstown/i
    return "Invercargill" if text =~ /invercargill/i
    return "Kapiti Coast" if text =~ /kapiti/i
    return "Online" if mapped_region == "online"

    nil
  end
end
```

- [ ] **Step 3: Add CSV manager with dedup logic**

Append to `scripts/pull_events.rb`:

```ruby
module CsvManager
  # Load existing events from CSV. Returns array of hashes.
  def self.load_existing(csv_path)
    return [] unless File.exist?(csv_path)

    CSV.read(csv_path, headers: true).map(&:to_h)
  end

  # Build a set of dedup keys from existing events
  def self.dedup_keys(events)
    events.each_with_object(Set.new) do |event, keys|
      key = dedup_key(event["title"], event["start_date"])
      keys.add(key) if key
    end
  end

  # Generate a dedup key from title + start_date
  def self.dedup_key(title, start_date)
    return nil if title.nil? || title.empty? || start_date.nil? || start_date.empty?
    "#{title.strip.downcase}||#{start_date.strip}"
  end

  # Write events to CSV
  def self.write(csv_path, events)
    dir = File.dirname(csv_path)
    Dir.mkdir(dir) unless Dir.exist?(dir)

    CSV.open(csv_path, "w", headers: EventBuilder::CSV_HEADERS, write_headers: true) do |csv|
      events.each { |event| csv << EventBuilder::CSV_HEADERS.map { |h| event[h] } }
    end
  end
end
```

- [ ] **Step 4: Run tests to verify nothing broke**

Run: `ruby test/scripts/pull_events_test.rb`
Expected: All tests still PASS

---

## Task 4: Add dedup tests

**Files:**
- Modify: `test/scripts/pull_events_test.rb`

- [ ] **Step 1: Write dedup tests**

Append to `test/scripts/pull_events_test.rb`:

```ruby
class CsvManagerTest < Minitest::Test
  def test_dedup_key_matches_same_event
    key1 = CsvManager.dedup_key("March AI Meetup", "2026-03-02")
    key2 = CsvManager.dedup_key("March AI Meetup", "2026-03-02")
    assert_equal key1, key2
  end

  def test_dedup_key_case_insensitive_title
    key1 = CsvManager.dedup_key("March AI Meetup", "2026-03-02")
    key2 = CsvManager.dedup_key("march ai meetup", "2026-03-02")
    assert_equal key1, key2
  end

  def test_dedup_key_different_date_no_match
    key1 = CsvManager.dedup_key("March AI Meetup", "2026-03-02")
    key2 = CsvManager.dedup_key("March AI Meetup", "2026-04-06")
    refute_equal key1, key2
  end

  def test_dedup_key_nil_title_returns_nil
    assert_nil CsvManager.dedup_key(nil, "2026-03-02")
  end

  def test_dedup_key_blank_date_returns_nil
    assert_nil CsvManager.dedup_key("Some Event", "")
  end

  def test_dedup_keys_from_events
    events = [
      { "title" => "Event A", "start_date" => "2026-03-01" },
      { "title" => "Event B", "start_date" => "2026-03-02" }
    ]
    keys = CsvManager.dedup_keys(events)
    assert_includes keys, "event a||2026-03-01"
    assert_includes keys, "event b||2026-03-02"
    assert_equal 2, keys.size
  end
end
```

- [ ] **Step 2: Run tests**

Run: `ruby test/scripts/pull_events_test.rb`
Expected: All tests PASS

---

## Task 5: Add main entry point

**Files:**
- Modify: `scripts/pull_events.rb`

- [ ] **Step 1: Add main runner at the bottom of the script**

Append to `scripts/pull_events.rb`:

```ruby
# --- Main entry point ---
# Only runs when executed directly (not when required by tests)
if __FILE__ == $PROGRAM_NAME
  CSV_PATH = File.expand_path("../data/events.csv", __dir__)

  puts "=== TechEvents Google Sheet Puller ==="
  puts ""

  # Load existing CSV
  existing_events = CsvManager.load_existing(CSV_PATH)
  existing_keys = CsvManager.dedup_keys(existing_events)
  puts "Existing events in CSV: #{existing_events.size}"

  # Determine which tabs to fetch
  tabs = SheetFetcher.tabs_to_fetch
  puts "Tabs to fetch: #{tabs.map { |t| t[:name] }.join(', ')}"
  puts ""

  new_events = []
  skipped = 0
  errors = []

  tabs.each do |tab|
    print "Fetching #{tab[:name]}... "
    begin
      rows = SheetFetcher.fetch_tab(tab)
      tab_new = 0
      tab_skipped = 0

      rows.each do |row|
        event = EventBuilder.build(row)
        key = CsvManager.dedup_key(event["title"], event["start_date"])

        if key.nil?
          puts "\n  WARNING: Could not generate key for '#{row[:title]}' (date: #{row[:date_raw]})"
          # Still add it - better to have it with no date than to lose it
          new_events << event
          tab_new += 1
        elsif existing_keys.include?(key)
          tab_skipped += 1
          skipped += 1
        else
          new_events << event
          existing_keys.add(key)
          tab_new += 1
        end
      end

      puts "#{rows.size} rows, #{tab_new} new, #{tab_skipped} existing"
    rescue => e
      puts "ERROR: #{e.message}"
      errors << { tab: tab[:name], error: e.message }
    end
  end

  # Merge: existing events first, then new events appended
  all_events = existing_events + new_events

  # Write output
  CsvManager.write(CSV_PATH, all_events)

  puts ""
  puts "=== Summary ==="
  puts "New events added: #{new_events.size}"
  puts "Existing events skipped: #{skipped}"
  puts "Total events in CSV: #{all_events.size}"
  puts "Output: #{CSV_PATH}"

  if errors.any?
    puts ""
    puts "Errors:"
    errors.each { |e| puts "  #{e[:tab]}: #{e[:error]}" }
  end
end
```

- [ ] **Step 2: Create data/.gitkeep**

```bash
mkdir -p data && touch data/.gitkeep
```

- [ ] **Step 3: Run all tests one final time**

Run: `ruby test/scripts/pull_events_test.rb`
Expected: All tests PASS

---

## Task 6: Integration test - run the script

**Files:**
- Run: `scripts/pull_events.rb`
- Verify: `data/events.csv`

- [ ] **Step 1: Run the script for the first time**

Run: `ruby scripts/pull_events.rb`
Expected output:
```
=== TechEvents Google Sheet Puller ===

Existing events in CSV: 0
Tabs to fetch: Mar 2026, Apr 2026, May 2026, ...

Fetching Mar 2026... ~48 rows, 48 new, 0 existing
Fetching Apr 2026... N rows, N new, 0 existing
...

=== Summary ===
New events added: <N>
Existing events skipped: 0
Total events in CSV: <N>
Output: /Users/rowan/www/tech-events/data/events.csv
```

- [ ] **Step 2: Verify the CSV output looks correct**

Run: `head -5 data/events.csv`
Expected: CSV with headers and first few events with correct dates, regions, etc.

Run: `wc -l data/events.csv`
Expected: Header row + N data rows

- [ ] **Step 3: Run the script again to verify dedup works**

Run: `ruby scripts/pull_events.rb`
Expected output should show:
```
New events added: 0
Existing events skipped: <N>
```

- [ ] **Step 4: Verify existing data preserved (spot check TechEventsID and ai_updated)**

Run: `head -3 data/events.csv | cut -d',' -f1,21`
Expected: `TechEventsID` header, then empty values. `ai_updated` should be `false`.
