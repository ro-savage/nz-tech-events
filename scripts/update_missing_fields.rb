require 'csv'

# Read the CSV
csv_content = File.read('data/events.csv')
rows = CSV.parse(csv_content, headers: true)

# Define updates for events without TechEventsID
# Key: [title, start_date] or just title for recurring
# Value: hash of fields to set (only fills in blanks)

TITLE_UPDATES = {
  "DINZ Virtual Coffee Chat" => {
    event_type: "networking",
    end_time: "10:45",
    # region/city already correct (online/Online)
  },
  "Kapiti Startup & Innovation Network" => {
    event_type: "networking",
    end_time: "09:00",
    cost: "Free",
    # region=wellington, city=Kapiti Coast already correct
  },
  "Auckland Makes Games" => {
    event_type: "networking",
    # region=auckland, city=Auckland CBD already correct
  },
  "Cryptocurrency NZ Meetup" => {
    event_type: "meetup",
    # region=online already correct (multi-location)
  },
  "Agritech Unleashed" => {
    event_type: "conference",
  },
}

SPECIFIC_UPDATES = {
  ["FLINT Auckland - Startups VS Corporates - Shaping Your Career", "2026-04-08"] => {
    event_type: "talk",
    end_time: "19:30",
    cost: "Free",
  },
  ["Nelson - Empower Her Networking - The Story Behind the Brand", "2026-04-10"] => {
    event_type: "networking",
    region: "nelson",
    city: "Nelson",
  },
  ["GEN NZ Motu Connect", "2026-04-14"] => {
    event_type: "networking",
  },
  ["Women and Non-Binary Folk STEM TRG - The Leadership Series", "2026-04-14"] => {
    event_type: "workshop",
    end_time: "19:30",
    cost: "Free",
  },
  ["KiwiSaaS | GTM Engineering: automate, scale, win", "2026-04-15"] => {
    event_type: "workshop",
    end_time: "19:30",
    cost: "$25",
  },
  ["\u{1F525} Job Hackers Mixer \u{2014} Live Q&A, Real Stories & Breakout Connections", "2026-04-15"] => {
    event_type: "networking",
    end_time: "20:00",
    cost: "Free",
  },
  ["Agritech Unleashed", "2026-04-16"] => {
    # region=auckland already correct
  },
  ["Fintech Festival", "2026-04-16"] => {
    event_type: "conference",
    end_time: "19:00",
  },
  ["EdTechNZ Community Connect Event \u{2013} Auckland", "2026-04-16"] => {
    event_type: "networking",
    cost: "Free",
  },
  ["EdTechNZ Community Connect Event \u{2013} Wellington", "2026-04-16"] => {
    event_type: "networking",
    cost: "Free",
  },
  ["EdTechNZ Community Connect Event \u{2013} Christchurch", "2026-04-16"] => {
    event_type: "networking",
    cost: "Free",
  },
  ["Prompt Like a Pro: Practical AI Techniques", "2026-04-17"] => {
    event_type: "workshop",
  },
  ["AI Forum Webinar Series: Real AI Case Studies and Success Stories from the Field", "2026-04-17"] => {
    event_type: "webinar",
    end_time: "10:30",
    cost: "Free",
  },
  ["EdTechNZ Community Connect Event", "2026-04-18"] => {
    event_type: "networking",
    cost: "Free",
  },
  ["Governance for Growth", "2026-04-20"] => {
    event_type: "workshop",
  },
  ["Movac Sales Jam", "2026-04-21"] => {
    event_type: "networking",
    end_time: "18:30",
  },
  ["AI Engineering TRG | 0.1 Setup", "2026-04-21"] => {
    event_type: "meetup",
    end_time: "19:30",
    cost: "Free",
  },
  ["Careers of the Future: Global Opportunities", "2026-04-21"] => {
    event_type: "talk",
    end_time: "19:30",
    cost: "Free",
  },
  ["Cleantech Expo - Auckland", "2026-04-22"] => {
    event_type: "conference",
    end_time: "15:00",
    cost: "Free",
  },
  ["Ministry of Awesome: Coffee & Jam - #370", "2026-04-23"] => {
    event_type: "meetup",
    end_time: "13:15",
    cost: "Free",
  },
  ["Think aloud! 30-min chat for people doing product research", "2026-04-27"] => {
    event_type: "networking",
    end_time: "09:00",
    cost: "Free",
  },
  ["VenturEd Live", "2026-04-29"] => {
    event_type: "conference",
    end_date: "2026-05-06",
    end_time: "18:30",
    cost: "$120",
  },
  ["Aurora Climate Lab Launch night", "2026-04-29"] => {
    event_type: "networking",
    end_time: "19:30",
    cost: "Free",
  },
  ["Network on Your Terms with Powrsuit &  W\u{0101}hine Fuelled Tech", "2026-04-30"] => {
    event_type: "networking",
    end_time: "19:30",
    cost: "Free",
  },
  ["VESA Hackathon 2026", "2026-05-01"] => {
    event_type: "hackathon",
    # end_date already set to 2026-05-03
  },
  ["AI and Creativity Summit", "2026-05-05"] => {
    event_type: "conference",
  },
  ["Soda Power Lunch with AJ Tills", "2026-05-05"] => {
    event_type: "talk",
    end_time: "13:30",
    cost: "$25",
  },
  ["AI and Creativity Summit", "2026-05-06"] => {
    event_type: "conference",
  },
  ["PowerUp Accelerator Showcase Night 2026", "2026-05-13"] => {
    event_type: "talk",
    end_time: "20:30",
    city: "New Plymouth",
  },
  ["AI Forum Webinar Series: Governance, Risk & Compliance", "2026-05-15"] => {
    event_type: "webinar",
    end_time: "10:30",
    cost: "Free",
  },
  ["Marketers Day Auckland", "2026-05-22"] => {
    event_type: "conference",
    end_time: "17:00",
    region: "auckland",
    city: "Auckland CBD",
  },
  ["Seeds Impact Conference 2026", "2026-05-22"] => {
    event_type: "conference",
    end_time: "16:30",
    cost: "Free",
  },
  ["AANZ Expert Session Legal Essentials for Early-Stage Companies", "2026-05-27"] => {
    event_type: "webinar",
    end_time: "11:30",
  },
  ["KPIs That Drive Profit Presented by Excel in BI NZ", "2026-05-05"] => {
    event_type: "webinar",
    end_time: "10:00",
    cost: "Free",
  },
  ["Migrants in Tech", "2026-06-25"] => {
    event_type: "networking",
  },
  ["Startup Weekend Taranaki 2026", "2026-07-31"] => {
    event_type: "hackathon",
    # end_date already set to 2026-08-02
    city: "Hawera",
  },
  ["Revved. Powerful Minds. Limitless Acceleration.", "2026-08-06"] => {
    event_type: "conference",
  },
  ["Agritech Unleashed", "2026-08-25"] => {
    # region=bay_of_plenty, city=Tauranga already correct
  },
  ["CryptoWinter26", "2026-08-25"] => {
    event_type: "conference",
    end_date: "2026-08-27",
  },
  ["AUT Innovation Showcase", "2026-09-03"] => {
    event_type: "conference",
    end_time: "20:00",
    cost: "Free",
  },
  ["Aotearoa AI Summit", "2026-09-08"] => {
    event_type: "conference",
    # end_date already set to 2026-09-09
  },
  ["KiwiSaaS Wellington conference", "2026-09-24"] => {
    event_type: "conference",
  },
  ["KiwiSaaS Auckland Event", "2026-10-15"] => {
    event_type: "conference",
  },
  ["Agritech Unleashed", "2026-11-12"] => {
    # region=otago already correct
    city: "Dunedin",
  },
  ["Maui Venture Summit", "2026-11-26"] => {
    event_type: "conference",
  },
}

updated_count = 0
changes = []

rows.each do |row|
  tech_events_id = row['TechEventsID'].to_s.strip
  next unless tech_events_id.empty?

  title = row['title'].to_s.strip
  start_date = row['start_date'].to_s.strip

  # Get updates: specific first, then title-level
  updates = {}
  updates.merge!(TITLE_UPDATES[title] || {})
  updates.merge!(SPECIFIC_UPDATES[[title, start_date]] || {})

  next if updates.empty?

  row_changes = []

  updates.each do |field, value|
    field_str = field.to_s
    current = row[field_str].to_s.strip

    # Only fill in blank/empty fields (don't overwrite existing data)
    # Exception: region, city, end_date can be updated even if set (to fix incorrect values)
    should_update = current.empty? || %w[region city end_date].include?(field_str)

    if should_update && current != value.to_s
      row[field_str] = value.to_s
      row_changes << "#{field_str}: '#{current}' -> '#{value}'"
    end
  end

  if row_changes.any?
    updated_count += 1
    changes << "#{title} (#{start_date}): #{row_changes.join(', ')}"
    puts "Updated: #{title} (#{start_date})"
    row_changes.each { |c| puts "  #{c}" }
  end
end

# Write back
CSV.open('data/events.csv', 'w') do |csv|
  csv << rows.headers
  rows.each { |row| csv << row }
end

puts "\n--- Summary ---"
puts "Updated: #{updated_count} events"
