require "csv"
require "json"
require "net/http"
require "uri"
require "set"

API_BASE = ENV.fetch("TECHEVENTS_API_URL", "https://techevents.co.nz/api/v1")
TECHEVENTS_CSV_PATH = File.expand_path("../data/techevents.csv", __dir__)
EVENTS_CSV_PATH = File.expand_path("../data/events.csv", __dir__)

TECHEVENTS_HEADERS = %w[
  id
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
  address
  regions
  cities
  approved
  created_at
  updated_at
].freeze

module TechEventsApi
  # Fetch all events (upcoming + past) from the API, paginated
  def self.fetch_all_events
    events = []
    events += fetch_scope("upcoming")
    events += fetch_scope("past")
    events
  end

  def self.fetch_scope(scope)
    events = []
    page = 1

    loop do
      params = { page: page, per_page: 100 }
      params[:scope] = scope if scope == "past"

      url = "#{API_BASE}/events?#{URI.encode_www_form(params)}"
      print "  Fetching #{scope} page #{page}... "

      response = Net::HTTP.get_response(URI(url))
      unless response.is_a?(Net::HTTPSuccess)
        puts "ERROR: #{response.code} #{response.message}"
        break
      end

      data = JSON.parse(response.body)
      batch = data["events"] || []
      meta = data["meta"] || {}

      puts "#{batch.size} events"
      events += batch

      break if page >= (meta["total_pages"] || 1)
      page += 1
    end

    events
  end

  # Flatten an API event hash into a CSV-ready row
  def self.to_csv_row(event)
    locations = event["locations"] || []
    regions = locations.map { |l| l["region"] }.compact.join("; ")
    cities = locations.map { |l| l["city"] }.compact.join("; ")

    {
      "id" => event["id"],
      "title" => event["title"],
      "short_summary" => event["short_summary"],
      "description_markdown" => event["description_markdown"],
      "start_date" => event["start_date"],
      "end_date" => event["end_date"],
      "start_time" => event["start_time"],
      "end_time" => event["end_time"],
      "cost" => event["cost"],
      "event_type" => event["event_type"],
      "registration_url" => event["registration_url"],
      "address" => event["address"],
      "regions" => regions,
      "cities" => cities,
      "approved" => event["approved"],
      "created_at" => event["created_at"],
      "updated_at" => event["updated_at"]
    }
  end
end

# --- Main ---
if __FILE__ == $PROGRAM_NAME
  puts "=== TechEvents API Puller ==="
  puts ""

  # Step 1: Fetch all events from the API
  puts "Fetching events from #{API_BASE}..."
  api_events = TechEventsApi.fetch_all_events
  puts "\nTotal API events fetched: #{api_events.size}"

  # Convert to CSV rows
  csv_rows = api_events.map { |e| TechEventsApi.to_csv_row(e) }

  # Step 2: Load the Google Sheet CSV and find already-matched TechEventsIDs
  matched_ids = Set.new
  if File.exist?(EVENTS_CSV_PATH)
    sheet_events = CSV.read(EVENTS_CSV_PATH, headers: true)
    sheet_events.each do |row|
      tech_id = row["TechEventsID"]
      matched_ids.add(tech_id.to_i) if tech_id && !tech_id.strip.empty?
    end
    puts "\nAlready-matched TechEventsIDs in events.csv: #{matched_ids.size}"
  else
    puts "\nNo events.csv found - skipping match filtering"
  end

  # Step 3: Remove already-matched events from the API data
  before_count = csv_rows.size
  csv_rows.reject! { |row| matched_ids.include?(row["id"].to_i) }
  removed = before_count - csv_rows.size
  puts "Removed #{removed} already-matched events"

  # Step 4: Write the filtered techevents CSV
  dir = File.dirname(TECHEVENTS_CSV_PATH)
  Dir.mkdir(dir) unless Dir.exist?(dir)

  CSV.open(TECHEVENTS_CSV_PATH, "w", headers: TECHEVENTS_HEADERS, write_headers: true) do |csv|
    csv_rows.each { |row| csv << TECHEVENTS_HEADERS.map { |h| row[h] } }
  end

  puts ""
  puts "=== Summary ==="
  puts "API events fetched: #{api_events.size}"
  puts "Already matched (removed): #{removed}"
  puts "Unmatched events written: #{csv_rows.size}"
  puts "Output: #{TECHEVENTS_CSV_PATH}"
end
