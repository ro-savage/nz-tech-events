require "csv"
require "json"
require "net/http"
require "uri"

API_BASE = ENV.fetch("TECHEVENTS_API_URL", "http://localhost:3000/api/v1")
API_TOKEN = ENV.fetch("TECHEVENTS_API_TOKEN") { abort "Error: TECHEVENTS_API_TOKEN env var is required" }
EVENTS_CSV_PATH = File.expand_path("../data/events.csv", __dir__)
ERRORS_CSV_PATH = File.expand_path("../data/events_errors.csv", __dir__)
REQUEST_DELAY = 2 # seconds between requests to stay under 30/min rate limit

# The CSV header has a typo — map it to the correct API field
CSV_DESCRIPTION_COLUMN = "description_markdowndescription_markdown"

# CSV columns that map directly to API event fields
DIRECT_FIELD_MAPPING = {
  "title" => "title",
  "short_summary" => "short_summary",
  CSV_DESCRIPTION_COLUMN => "description_markdown",
  "start_date" => "start_date",
  "end_date" => "end_date",
  "start_time" => "start_time",
  "end_time" => "end_time",
  "cost" => "cost",
  "event_type" => "event_type",
  "registration_url" => "registration_url",
  "address" => "address",
  "source" => "source",
  "source_url" => "source_url"
}.freeze

def build_event_json(row)
  event = {}
  DIRECT_FIELD_MAPPING.each do |csv_col, api_field|
    value = row[csv_col]
    event[api_field] = value if value && !value.strip.empty?
  end

  # Build locations array from region/city
  region = row["region"]
  if region && !region.strip.empty?
    location = { "region" => region.strip }
    city = row["city"]
    location["city"] = city.strip if city && !city.strip.empty?
    event["locations"] = [location]
  end

  { "event" => event }
end

def post_event(json_body)
  uri = URI("#{API_BASE}/events")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == "https"

  request = Net::HTTP::Post.new(uri.path)
  request["Content-Type"] = "application/json"
  request["Authorization"] = "Bearer #{API_TOKEN}"
  request.body = JSON.generate(json_body)

  response = http.request(request)
  [response.code.to_i, JSON.parse(response.body)]
rescue JSON::ParserError
  [response.code.to_i, { "error" => response.body }]
rescue StandardError => e
  [0, { "error" => e.message }]
end

def format_error(status, body)
  if body["errors"]
    body["errors"].map { |field, messages| "#{field}: #{Array(messages).join(", ")}" }.join("; ")
  elsif body["error"]
    body["error"]
  else
    "HTTP #{status}: #{body}"
  end
end

# --- Main ---
if __FILE__ == $PROGRAM_NAME
  puts "=== TechEvents CSV Uploader ==="
  puts "API: #{API_BASE}"
  puts ""

  unless File.exist?(EVENTS_CSV_PATH)
    abort "Error: #{EVENTS_CSV_PATH} not found"
  end

  rows = CSV.read(EVENTS_CSV_PATH, headers: true)
  headers = rows.headers

  to_upload = []
  skipped = 0

  rows.each_with_index do |row, index|
    tech_id = row["TechEventsID"]
    if tech_id && !tech_id.strip.empty?
      skipped += 1
    else
      to_upload << [index, row]
    end
  end

  puts "Total rows: #{rows.size}"
  puts "Already uploaded (skipping): #{skipped}"
  puts "To upload: #{to_upload.size}"
  puts ""

  if to_upload.empty?
    puts "Nothing to upload."
    exit 0
  end

  uploaded = 0
  errors = []

  to_upload.each_with_index do |(row_index, row), i|
    title = row["title"] || "(no title)"
    print "[#{i + 1}/#{to_upload.size}] #{title[0..60]}... "

    json_body = build_event_json(row)
    status, body = post_event(json_body)

    if status == 201
      event_id = body["id"]
      rows[row_index]["TechEventsID"] = event_id.to_s
      uploaded += 1
      puts "OK (id=#{event_id})"
    else
      error_msg = format_error(status, body)
      errors << [row_index, row, error_msg]
      puts "ERROR: #{error_msg}"
    end

    sleep REQUEST_DELAY if i < to_upload.size - 1
  end

  # Write updated events.csv with new TechEventsIDs
  CSV.open(EVENTS_CSV_PATH, "w", headers: headers, write_headers: true) do |csv|
    rows.each { |row| csv << headers.map { |h| row[h] } }
  end
  puts ""
  puts "Updated #{EVENTS_CSV_PATH}"

  # Write error CSV if there were failures
  if errors.any?
    error_headers = ["error"] + headers
    CSV.open(ERRORS_CSV_PATH, "w", headers: error_headers, write_headers: true) do |csv|
      errors.each do |_row_index, row, error_msg|
        csv << [error_msg] + headers.map { |h| row[h] }
      end
    end
    puts "Errors written to #{ERRORS_CSV_PATH}"
  end

  puts ""
  puts "=== Summary ==="
  puts "Uploaded: #{uploaded}"
  puts "Skipped:  #{skipped}"
  puts "Errors:   #{errors.size}"
  puts "Total:    #{rows.size}"
end
