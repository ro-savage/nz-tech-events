# Seed data for NZ Tech Events
# Idempotent: safe to run multiple times via `bin/rails db:seed`

puts "Seeding NZ Tech Events..."

# ---------------------------------------------------------------------------
# Users
# ---------------------------------------------------------------------------
puts "\nCreating users..."

admin = User.find_or_create_by!(email_address: "admin@example.com") do |u|
  u.password = "password123"
  u.name = "Admin User"
  u.admin = true
  u.approved_organiser = true
end
puts "  #{admin.persisted? ? 'Found' : 'Created'} admin: admin@example.com (admin)"

organiser = User.find_or_create_by!(email_address: "organiser@example.com") do |u|
  u.password = "password123"
  u.name = "Sarah Chen"
  u.approved_organiser = true
end
puts "  #{organiser.persisted? ? 'Found' : 'Created'} organiser: organiser@example.com (approved organiser)"

regular_user = User.find_or_create_by!(email_address: "user@example.com") do |u|
  u.password = "password123"
  u.name = "James Wilson"
end
puts "  #{regular_user.persisted? ? 'Found' : 'Created'} regular user: user@example.com"

# Keep the legacy test user so existing docs/test credentials still work
test_user = User.find_or_create_by!(email_address: "test@example.com") do |u|
  u.password = "password123"
  u.name = "Test User"
  u.admin = true
  u.approved_organiser = true
end
puts "  #{test_user.persisted? ? 'Found' : 'Created'} test user: test@example.com (admin + organiser)"

# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------
def loc(region:, city: nil, position: 0)
  { region: region, city: city, position: position }
end

def find_or_create_event!(attrs)
  existing = Event.find_by(title: attrs[:title], start_date: attrs[:start_date])
  return existing if existing

  Event.create!(attrs)
end

# ---------------------------------------------------------------------------
# Upcoming events (next 1-3 months)
# ---------------------------------------------------------------------------
puts "\nCreating upcoming events..."

upcoming_events = [
  {
    title: "Auckland Python Meetup",
    description: "Monthly gathering for Python enthusiasts in Auckland. This month we have two talks: building REST APIs with FastAPI, and an intro to data pipelines with Polars. Pizza and drinks provided.",
    short_summary: "Monthly Python meetup with talks on FastAPI and Polars.",
    start_date: Date.current + 7.days,
    start_time: "18:00",
    end_time: "20:30",
    event_type: :meetup,
    cost: "Free",
    user: organiser,
    event_locations_attributes: [loc(region: :auckland, city: "Auckland CBD")]
  },
  {
    title: "Wellington DevOps Workshop",
    description: "Hands-on workshop covering CI/CD pipelines with GitHub Actions, infrastructure as code with Terraform, and container orchestration with Kubernetes. Bring your laptop with Docker installed. Lunch included.",
    short_summary: "Full-day hands-on DevOps workshop covering GitHub Actions, Terraform, and Kubernetes.",
    start_date: Date.current + 14.days,
    start_time: "09:00",
    end_time: "17:00",
    event_type: :workshop,
    cost: "$50 early bird / $75 standard",
    registration_url: "https://example.com/welly-devops",
    user: organiser,
    event_locations_attributes: [loc(region: :wellington, city: "Wellington CBD")]
  },
  {
    title: "NZ JavaScript Conference 2026",
    description: "The premier JavaScript conference in Aotearoa New Zealand. Two days of talks from local and international speakers covering TypeScript, React Server Components, Deno 2, edge computing, and the future of the web platform. Includes workshops, hallway track, and conference dinner.",
    short_summary: "Two-day JS conference with local and international speakers.",
    start_date: Date.current + 30.days,
    end_date: Date.current + 31.days,
    start_time: "08:30",
    end_time: "17:30",
    event_type: :conference,
    cost: "$199 + GST",
    registration_url: "https://example.com/nzjsconf",
    user: admin,
    event_locations_attributes: [loc(region: :auckland, city: "Auckland CBD")]
  },
  {
    title: "Christchurch AI Hackathon",
    description: "48-hour hackathon focused on practical AI applications for New Zealand businesses. Teams of 2-5 people. Mentors from local AI companies available throughout. Prizes include $5,000 cash, cloud credits, and co-working space memberships.",
    short_summary: "48-hour AI hackathon with $5,000 in prizes.",
    start_date: Date.current + 21.days,
    end_date: Date.current + 23.days,
    start_time: "18:00",
    event_type: :hackathon,
    cost: "$25",
    registration_url: "https://example.com/chch-ai-hack",
    user: organiser,
    event_locations_attributes: [loc(region: :canterbury, city: "Christchurch")]
  },
  {
    title: "Online Cloud Native Webinar",
    description: "Join us for a lunchtime webinar on cloud-native architecture patterns. Covering microservices vs monoliths, service mesh, observability, and cost optimisation strategies for AWS and Azure. Q&A session at the end.",
    short_summary: "Lunchtime webinar on cloud-native architecture patterns.",
    start_date: Date.current + 5.days,
    start_time: "12:00",
    end_time: "13:00",
    event_type: :webinar,
    cost: "Free",
    registration_url: "https://zoom.us/example-cloud-native",
    user: admin,
    event_locations_attributes: [loc(region: :online, city: "Online")]
  },
  {
    title: "Hamilton Tech Networking Drinks",
    description: "Informal networking for Waikato tech workers. No agenda, just good conversation over drinks. Whether you are a developer, designer, PM, or founder, come meet others in the local tech scene. First drink on us.",
    short_summary: "Casual networking drinks for Waikato tech professionals.",
    start_date: Date.current + 10.days,
    start_time: "17:30",
    end_time: "19:30",
    event_type: :networking,
    cost: "Free",
    user: organiser,
    event_locations_attributes: [loc(region: :waikato, city: "Hamilton")]
  },
  {
    title: "Wellington Engineering Leadership Talk",
    description: "An evening talk on scaling engineering teams from 5 to 50 people. Covering hiring, onboarding, decision-making under uncertainty, and practical leadership lessons from NZ tech leaders. Followed by networking and refreshments.",
    short_summary: "Evening talk on scaling engineering teams with local tech leaders.",
    start_date: Date.current + 12.days,
    start_time: "18:00",
    end_time: "19:30",
    event_type: :talk,
    cost: "Free",
    user: admin,
    event_locations_attributes: [loc(region: :wellington, city: "Wellington CBD")]
  },
  {
    title: "Auckland Cloud Infrastructure Meetup",
    description: "Monthly meetup for cloud infrastructure professionals. This month: serverless architectures on AWS Lambda and Azure Functions, plus a lightning talk on cost optimisation. Sponsored by a local cloud consultancy.",
    short_summary: "Monthly cloud infra meetup covering serverless and cost optimisation.",
    start_date: Date.current + 9.days,
    start_time: "18:30",
    end_time: "20:30",
    event_type: :meetup,
    cost: "Free",
    user: organiser,
    event_locations_attributes: [loc(region: :auckland, city: "North Shore")]
  },
  {
    title: "Dunedin Data Science Workshop",
    description: "Learn data science fundamentals with real-world NZ datasets. Covering pandas, scikit-learn, and data visualisation with matplotlib. Suitable for beginners with some Python experience. Laptops provided if needed.",
    short_summary: "Beginner-friendly data science workshop with real NZ datasets.",
    start_date: Date.current + 18.days,
    start_time: "09:00",
    end_time: "16:00",
    event_type: :workshop,
    cost: "$75",
    registration_url: "https://example.com/dunedin-datasci",
    user: admin,
    event_locations_attributes: [loc(region: :otago, city: "Dunedin")]
  },
  {
    title: "Tauranga Startup Pitch Night",
    description: "Five Bay of Plenty startups pitch to a panel of investors and mentors. Each team gets 10 minutes to present followed by 5 minutes of Q&A. Networking drinks afterwards. Open to anyone interested in the local startup scene.",
    short_summary: "Five local startups pitch to investors and mentors.",
    start_date: Date.current + 15.days,
    start_time: "18:00",
    end_time: "21:00",
    event_type: :networking,
    cost: "Free",
    user: organiser,
    event_locations_attributes: [loc(region: :bay_of_plenty, city: "Tauranga")]
  },
  {
    title: "NZ Cybersecurity Conference",
    description: "Annual cybersecurity conference for NZ organisations. Two days covering threat landscape, incident response, zero trust architecture, and compliance with the NZ Privacy Act. Keynote from CERT NZ. Early bird pricing available until two weeks before the event.",
    short_summary: "Two-day cybersecurity conference with CERT NZ keynote.",
    start_date: Date.current + 45.days,
    end_date: Date.current + 46.days,
    start_time: "08:30",
    end_time: "17:30",
    event_type: :conference,
    cost: "$350 + GST",
    registration_url: "https://example.com/nz-cybersec",
    user: admin,
    event_locations_attributes: [loc(region: :wellington, city: "Wellington CBD")]
  },
  {
    title: "React & TypeScript Workshop",
    description: "Build a full-stack application with React 19 and TypeScript. Covers Server Components, hooks patterns, state management with Zustand, and API integration. You will deploy a working app by the end of the day.",
    short_summary: "Full-day React 19 and TypeScript hands-on workshop.",
    start_date: Date.current + 28.days,
    start_time: "09:00",
    end_time: "17:00",
    event_type: :workshop,
    cost: "$150 + GST",
    registration_url: "https://example.com/react-ts-workshop",
    user: organiser,
    event_locations_attributes: [loc(region: :auckland, city: "Auckland CBD")]
  },
  {
    title: "Intro to Kubernetes Webinar",
    description: "A beginner-friendly webinar covering container orchestration with Kubernetes. Learn about pods, services, deployments, ConfigMaps, and Helm charts. No prior container experience required.",
    short_summary: "Beginner-friendly Kubernetes webinar covering core concepts.",
    start_date: Date.current + 8.days,
    start_time: "14:00",
    end_time: "15:30",
    event_type: :webinar,
    cost: "Free",
    registration_url: "https://example.com/k8s-webinar",
    user: admin,
    event_locations_attributes: [loc(region: :online, city: "Online")]
  },
  {
    title: "Nelson Tech Community Meetup",
    description: "Monthly meetup for tech enthusiasts in the Nelson region. Lightning talks, project show-and-tell, and networking. All skill levels and backgrounds welcome. This month: home automation with Raspberry Pi.",
    short_summary: "Monthly Nelson tech meetup with lightning talks and show-and-tell.",
    start_date: Date.current + 20.days,
    start_time: "18:00",
    end_time: "20:00",
    event_type: :meetup,
    cost: "Free",
    user: organiser,
    event_locations_attributes: [loc(region: :nelson, city: "Nelson")]
  },
  {
    title: "GovTech Hackathon Wellington",
    description: "Use open government data to build solutions for public good. Teams of 3-5 people. Mentors from government agencies available throughout the weekend. Datasets provided from Stats NZ, LINZ, and DOC.",
    short_summary: "Weekend hackathon using open government data for public good.",
    start_date: Date.current + 35.days,
    end_date: Date.current + 37.days,
    start_time: "09:00",
    event_type: :hackathon,
    cost: "Free",
    registration_url: "https://example.com/govtech-hack",
    user: admin,
    event_locations_attributes: [loc(region: :wellington, city: "Wellington CBD")]
  },
  {
    title: "Canterbury Tech Excellence Awards",
    description: "Celebrating standout teams and individuals across the Canterbury tech ecosystem. Awards, short acceptance talks, dinner, and networking. Categories include Best Startup, Best Open Source Project, and Tech Leader of the Year.",
    short_summary: "Awards ceremony celebrating Canterbury tech achievements.",
    start_date: Date.current + 50.days,
    start_time: "18:30",
    end_time: "22:00",
    event_type: :awards,
    cost: "$120",
    registration_url: "https://example.com/canterbury-awards",
    user: organiser,
    event_locations_attributes: [loc(region: :canterbury, city: "Christchurch")]
  },
  # Multi-location event
  {
    title: "NZ Women in Tech Meetup",
    description: "Simultaneous meetups in Auckland and Wellington for women and non-binary people in tech. Panel discussion on career progression, mentoring circles, and networking. All allies welcome.",
    short_summary: "Simultaneous Auckland and Wellington meetups for women in tech.",
    start_date: Date.current + 22.days,
    start_time: "18:00",
    end_time: "20:00",
    event_type: :meetup,
    cost: "Free",
    user: admin,
    event_locations_attributes: [
      loc(region: :auckland, city: "Auckland CBD", position: 0),
      loc(region: :wellington, city: "Wellington CBD", position: 1)
    ]
  },
  # Pending events (created by regular user, not auto-approved)
  {
    title: "Napier Web Dev Meetup",
    description: "Casual meetup for web developers in Hawke's Bay. Bring your projects, questions, and ideas. We meet at a local cafe with good wifi and even better coffee.",
    short_summary: "Casual Hawke's Bay web dev meetup at a local cafe.",
    start_date: Date.current + 16.days,
    start_time: "10:00",
    end_time: "12:00",
    event_type: :meetup,
    cost: "Free",
    user: regular_user,
    event_locations_attributes: [loc(region: :hawkes_bay, city: "Napier")]
  },
  {
    title: "Palmerston North Coding Dojo",
    description: "Fortnightly coding dojo where we solve programming challenges in pairs. All languages welcome. Great way to practise test-driven development and learn from others.",
    short_summary: "Fortnightly pair-programming coding dojo.",
    start_date: Date.current + 24.days,
    start_time: "18:00",
    end_time: "20:00",
    event_type: :workshop,
    cost: "Free",
    user: regular_user,
    event_locations_attributes: [loc(region: :manawatu_whanganui, city: "Palmerston North")]
  }
]

upcoming_events.each do |event_data|
  event = find_or_create_event!(event_data)
  puts "  Created: #{event_data[:title]}"
end

# ---------------------------------------------------------------------------
# Past events
# ---------------------------------------------------------------------------
puts "\nCreating past events..."

past_events = [
  {
    title: "Auckland Tech Meetup - March",
    description: "End of Q1 wrap-up meetup with lightning talks covering Rails 8, Bun runtime, and the state of NZ tech hiring. Great turnout with over 80 attendees.",
    short_summary: "Q1 wrap-up with lightning talks on Rails 8 and Bun runtime.",
    start_date: Date.current - 14.days,
    start_time: "18:00",
    end_time: "20:00",
    event_type: :meetup,
    cost: "Free",
    user: admin,
    event_locations_attributes: [loc(region: :auckland, city: "Auckland CBD")]
  },
  {
    title: "Christchurch Web Dev Workshop",
    description: "Full-day workshop on modern web development with HTML, CSS, and vanilla JavaScript. Covered progressive enhancement, accessibility testing, and performance optimisation.",
    short_summary: "Full-day web dev workshop covering accessibility and performance.",
    start_date: Date.current - 30.days,
    start_time: "09:00",
    end_time: "17:00",
    event_type: :workshop,
    cost: "$60",
    user: organiser,
    event_locations_attributes: [loc(region: :canterbury, city: "Christchurch")]
  },
  {
    title: "Wellington Startup Weekend",
    description: "54-hour event where aspiring entrepreneurs pitched ideas, formed teams, and launched startups. Twelve teams presented to a panel of judges. Winner went on to join a local accelerator programme.",
    short_summary: "54-hour startup launch event with 12 teams competing.",
    start_date: Date.current - 60.days,
    end_date: Date.current - 58.days,
    start_time: "18:00",
    event_type: :hackathon,
    cost: "$99",
    user: admin,
    event_locations_attributes: [loc(region: :wellington, city: "Wellington CBD")]
  },
  {
    title: "API Design Best Practices Webinar",
    description: "Covered RESTful API design, versioning strategies, pagination patterns, and documentation with OpenAPI. Recording available on the event page.",
    short_summary: "Webinar on REST API design, versioning, and OpenAPI docs.",
    start_date: Date.current - 7.days,
    start_time: "12:00",
    end_time: "13:00",
    event_type: :webinar,
    cost: "Free",
    user: organiser,
    event_locations_attributes: [loc(region: :online, city: "Online")]
  },
  {
    title: "NZ Tech Awards Gala",
    description: "Annual celebration of excellence in New Zealand technology. Awards across 10 categories, keynote dinner, and networking. Over 300 attendees from across the country.",
    short_summary: "Annual NZ tech awards with 10 categories and 300+ attendees.",
    start_date: Date.current - 90.days,
    start_time: "18:00",
    end_time: "23:00",
    event_type: :awards,
    cost: "$175",
    user: admin,
    event_locations_attributes: [loc(region: :auckland, city: "Auckland CBD")]
  }
]

past_events.each do |event_data|
  event = find_or_create_event!(event_data)
  puts "  Created: #{event_data[:title]}"
end

# ---------------------------------------------------------------------------
# Email subscriptions
# ---------------------------------------------------------------------------
puts "\nCreating email subscriptions..."

subscriptions = [
  { email_address: "dev@example.com", region: :auckland },
  { email_address: "wellington-watcher@example.com", region: :wellington },
  { email_address: "chch-dev@example.com", region: :canterbury }
]

subscriptions.each do |sub_data|
  sub = EmailSubscription.find_or_create_by!(sub_data)
  puts "  Subscribed: #{sub_data[:email_address]} to #{sub_data[:region]}"
end

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
puts "\nSeed data created:"
puts "  Users: #{User.count}"
puts "  Events: #{Event.count} (#{Event.approved.count} approved, #{Event.pending_approval.count} pending)"
puts "  Event locations: #{EventLocation.count}"
puts "  Subscriptions: #{EmailSubscription.count}"
puts ""
puts "Login credentials (all passwords: password123):"
puts "  admin@example.com     - Admin"
puts "  organiser@example.com - Approved organiser"
puts "  user@example.com      - Regular user"
puts "  test@example.com      - Admin + organiser (legacy test account)"
