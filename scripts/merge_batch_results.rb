require "csv"
require "json"

CSV_PATH = File.expand_path("../data/events.csv", __dir__)
DATA_DIR = File.expand_path("../data", __dir__)

# Load existing CSV
events = CSV.read(CSV_PATH, headers: true).map(&:to_h)
puts "Loaded #{events.size} events from CSV"

# Find and load all batch JSON files
batch_files = Dir.glob(File.join(DATA_DIR, "batch_*.json")).sort
puts "Found #{batch_files.size} batch files: #{batch_files.map { |f| File.basename(f) }.join(', ')}"

updated_count = 0
errors = []

batch_files.each do |batch_file|
  begin
    batch_data = JSON.parse(File.read(batch_file))
    puts "\nProcessing #{File.basename(batch_file)} (#{batch_data.size} entries)..."

    batch_data.each do |entry|
      row_index = entry["row"].to_i - 1 # Convert 1-based row to 0-based index

      if row_index < 0 || row_index >= events.size
        puts "  WARNING: Row #{entry['row']} out of range, skipping"
        next
      end

      event = events[row_index]

      # Only update if not already AI-updated (preserve manual edits)
      if event["ai_updated"] == "true"
        puts "  Skipping row #{entry['row']} (#{event['title']}) - already AI updated"
        next
      end

      event["event_type"] = entry["event_type"] if entry["event_type"] && !entry["event_type"].empty?
      event["ai_description"] = entry["ai_description"] if entry["ai_description"] && !entry["ai_description"].empty?
      event["ai_updated"] = "true"
      updated_count += 1
    end
  rescue JSON::ParserError => e
    puts "  ERROR parsing #{File.basename(batch_file)}: #{e.message}"
    errors << batch_file
  rescue => e
    puts "  ERROR processing #{File.basename(batch_file)}: #{e.message}"
    errors << batch_file
  end
end

# Write updated CSV
headers = events.first.keys
CSV.open(CSV_PATH, "w", headers: headers, write_headers: true) do |csv|
  events.each { |event| csv << headers.map { |h| event[h] } }
end

puts "\n=== Summary ==="
puts "Events updated: #{updated_count}"
puts "Total events: #{events.size}"
puts "Output: #{CSV_PATH}"

if errors.any?
  puts "\nFailed batch files:"
  errors.each { |f| puts "  #{File.basename(f)}" }
end
