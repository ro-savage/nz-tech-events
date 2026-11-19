require_relative "pull_techevents"

# Writes every live event (upcoming + past) to data/techevents_all.csv.
# Unlike pull_techevents.rb it doesn't drop events already matched in
# events.csv, so /pull-events-websites can dedupe against the whole site.
TECHEVENTS_ALL_CSV_PATH = File.expand_path("../data/techevents_all.csv", __dir__)

module TechEventsDump
  def self.write(api_events, path)
    CSV.open(path, "w", headers: TECHEVENTS_HEADERS, write_headers: true) do |csv|
      api_events.each do |event|
        row = TechEventsApi.to_csv_row(event)
        csv << TECHEVENTS_HEADERS.map { |h| row[h] }
      end
    end
    api_events.size
  end
end

# --- Main ---
if __FILE__ == $PROGRAM_NAME
  puts "=== TechEvents API Dump ==="
  puts "Fetching events from #{API_BASE}..."
  count = TechEventsDump.write(TechEventsApi.fetch_all_events, TECHEVENTS_ALL_CSV_PATH)
  puts "\nWrote #{count} events to #{TECHEVENTS_ALL_CSV_PATH}"
end
