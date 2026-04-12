require "csv"
require "open-uri"
require "date"
require "time"
require "net/http"
require "set"

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

    # Try to find month in the text (check longer names first to avoid partial matches)
    month_num = nil
    MONTHS.sort_by { |name, _| -name.length }.each do |name, num|
      if text.downcase.include?(name)
        month_num = num
        break
      end
    end
    month_num ||= tab_month

    # Try cross-month date range: "31 Jul - 2 Aug"
    cross_month_match = text.match(/(\d{1,2})\s+(\w+)\s*[-–]\s*(\d{1,2})\s+(\w+)/i)
    if cross_month_match
      start_day = cross_month_match[1].to_i
      start_month = MONTHS[cross_month_match[2].downcase]
      end_day = cross_month_match[3].to_i
      end_month = MONTHS[cross_month_match[4].downcase]
      if start_month && end_month
        result[:start_date] = Date.new(tab_year, start_month, start_day)
        result[:end_date] = Date.new(tab_year, end_month, end_day)
        return result
      end
    end

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

    # Parse all rows without headers first - row 0 is a banner, row 1 is the real header
    all_rows = CSV.parse(csv_data)

    # Find the header row (the one containing "Date and time")
    header_index = all_rows.index { |row| row.any? { |cell| cell&.strip == "Date and time" } }
    return [] unless header_index

    headers = all_rows[header_index].map { |h| h&.strip }
    data_rows = all_rows[(header_index + 1)..]

    data_rows.filter_map do |row|
      # Build a hash using the discovered headers
      row_hash = {}
      headers.each_with_index { |h, i| row_hash[h] = row[i] if h && !h.empty? }

      title = row_hash["Event title"]&.strip
      next if title.nil? || title.empty?

      {
        date_raw: row_hash["Date and time"]&.strip,
        region_raw: row_hash["Region"]&.strip,
        title: title,
        blurb: row_hash["Blurb (keep it short and sweet)"]&.strip,
        event_mode: row_hash["In person/Online/Hybrid"]&.strip,
        organiser: row_hash["Organiser details"]&.strip,
        venue: row_hash["Venue"]&.strip,
        tickets_link: row_hash["Tickets link"]&.strip,
        notes: row_hash["Notes"]&.strip,
        tab_year: tab[:year],
        tab_month: tab[:month],
        tab_name: tab[:name],
        tab_gid: tab[:gid]
      }
    end
  end
end

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
