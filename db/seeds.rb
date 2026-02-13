# Clear existing data
puts "Clearing existing data..."
Event.destroy_all
EmailSubscription.destroy_all
User.destroy_all

# Create users
puts "Creating users..."

test_user = User.create!(
  email_address: "test@example.com",
  password: "password123",
  name: "Test User",
  approved_organiser: true,
  admin: true
)

sarah = User.create!(
  email_address: "sarah@example.com",
  password: "password123",
  name: "Sarah Chen",
  approved_organiser: true
)

james = User.create!(
  email_address: "james@example.com",
  password: "password123",
  name: "James Wilson",
  approved_organiser: true
)

aroha = User.create!(
  email_address: "aroha@example.com",
  password: "password123",
  name: "Aroha Ngata"
)

liam = User.create!(
  email_address: "liam@example.com",
  password: "password123",
  name: "Liam O'Brien"
)

# Helper to build location attributes
def loc(region:, city: nil, position: 0)
  { region: region, city: city, position: position }
end

# Create future events
puts "Creating future events..."

future_events = [
  {
    title: "Auckland JavaScript Meetup",
    description: "Join us for an evening of JavaScript talks and networking. We'll have two speakers covering modern JS frameworks and best practices for async programming.",
    start_date: Date.current + 7.days,
    start_time: "18:00",
    end_time: "21:00",
    event_type: :meetup,
    cost: "Free",
    user: test_user,
    event_locations_attributes: [loc(region: :auckland, city: "Auckland CBD")]
  },
  {
    title: "Wellington Tech Conference 2026",
    description: "The biggest tech conference in the capital! Two days of talks, workshops, and networking with the best minds in NZ tech.",
    start_date: Date.current + 30.days,
    end_date: Date.current + 31.days,
    start_time: "09:00",
    end_time: "17:00",
    event_type: :conference,
    cost: "$199",
    registration_url: "https://example.com/register",
    user: sarah,
    event_locations_attributes: [loc(region: :wellington, city: "Wellington CBD")]
  },
  {
    title: "Christchurch Python Workshop",
    description: "A hands-on workshop for Python beginners. Learn the basics of Python programming in a friendly, supportive environment.",
    start_date: Date.current + 14.days,
    start_time: "10:00",
    end_time: "16:00",
    event_type: :workshop,
    cost: "$50",
    user: james,
    event_locations_attributes: [loc(region: :canterbury, city: "Christchurch")]
  },
  {
    title: "Remote Work Webinar",
    description: "Tips and tricks for effective remote work. Join us online to learn from experienced remote workers across the Asia Pacific region.",
    start_date: Date.current + 3.days,
    start_time: "12:00",
    end_time: "13:00",
    event_type: :webinar,
    cost: "Free",
    registration_url: "https://zoom.us/example",
    user: aroha,
    event_locations_attributes: [loc(region: :online, city: "Online")]
  },
  {
    title: "Hamilton Hackathon",
    description: "48-hour hackathon! Build something amazing with fellow developers. Prizes for top projects including $5,000 for the winner.",
    start_date: Date.current + 45.days,
    end_date: Date.current + 47.days,
    start_time: "18:00",
    event_type: :hackathon,
    cost: "$25",
    user: liam,
    event_locations_attributes: [loc(region: :waikato, city: "Hamilton")]
  },
  {
    title: "Auckland Cloud Infrastructure Meetup",
    description: "Monthly meetup focused on AWS, Azure, and GCP. This month we're covering serverless architectures and cost optimisation strategies.",
    start_date: Date.current + 10.days,
    start_time: "18:30",
    end_time: "20:30",
    event_type: :meetup,
    cost: "Free",
    user: sarah,
    event_locations_attributes: [loc(region: :auckland, city: "Auckland CBD")]
  },
  {
    title: "Dunedin Data Science Workshop",
    description: "Learn data science fundamentals with real-world datasets. Covering pandas, scikit-learn, and data visualisation with matplotlib.",
    start_date: Date.current + 21.days,
    start_time: "09:00",
    end_time: "17:00",
    event_type: :workshop,
    cost: "$75",
    user: james,
    event_locations_attributes: [loc(region: :otago, city: "Dunedin")]
  },
  {
    title: "Wellington Ruby on Rails Meetup",
    description: "Monthly Rails meetup. This month: Rails 8 features deep dive, including Solid Cache, Solid Queue, and the new authentication generator.",
    start_date: Date.current + 5.days,
    start_time: "18:00",
    end_time: "20:00",
    event_type: :meetup,
    cost: "Free",
    user: aroha,
    event_locations_attributes: [loc(region: :wellington, city: "Wellington CBD")]
  },
  {
    title: "NZ Cybersecurity Conference",
    description: "Annual cybersecurity conference covering threat landscape, incident response, and security best practices for NZ organisations.",
    start_date: Date.current + 60.days,
    end_date: Date.current + 61.days,
    start_time: "08:30",
    end_time: "17:30",
    event_type: :conference,
    cost: "$350",
    registration_url: "https://example.com/cybersec",
    user: test_user,
    event_locations_attributes: [loc(region: :auckland, city: "Auckland CBD")]
  },
  {
    title: "Tauranga Startup Networking",
    description: "Connect with fellow founders and tech professionals in the Bay of Plenty. Casual drinks and conversation about the local startup scene.",
    start_date: Date.current + 12.days,
    start_time: "17:30",
    end_time: "19:30",
    event_type: :networking,
    cost: "Free",
    user: liam,
    event_locations_attributes: [loc(region: :bay_of_plenty, city: "Tauranga")]
  },
  {
    title: "Intro to Kubernetes Webinar",
    description: "A beginner-friendly webinar covering container orchestration with Kubernetes. Learn about pods, services, deployments, and more.",
    start_date: Date.current + 8.days,
    start_time: "14:00",
    end_time: "15:30",
    event_type: :webinar,
    cost: "Free",
    registration_url: "https://example.com/k8s-webinar",
    user: sarah,
    event_locations_attributes: [loc(region: :online, city: "Online")]
  },
  {
    title: "Auckland AI/ML Meetup",
    description: "Exploring practical applications of AI and machine learning in NZ businesses. Two talks plus Q&A and networking.",
    start_date: Date.current + 18.days,
    start_time: "18:00",
    end_time: "20:30",
    event_type: :meetup,
    cost: "Free",
    user: james,
    event_locations_attributes: [loc(region: :auckland, city: "North Shore")]
  },
  {
    title: "Wellington UX Design Workshop",
    description: "Hands-on workshop covering user research methods, wireframing, and prototyping. Bring your laptop with Figma installed.",
    start_date: Date.current + 25.days,
    start_time: "09:30",
    end_time: "16:30",
    event_type: :workshop,
    cost: "$120",
    user: aroha,
    event_locations_attributes: [loc(region: :wellington, city: "Wellington CBD")]
  },
  {
    title: "Queenstown Tech Retreat",
    description: "A weekend of talks, workshops, and outdoor activities for tech professionals. Combine learning with adventure in beautiful Queenstown.",
    start_date: Date.current + 50.days,
    end_date: Date.current + 52.days,
    start_time: "10:00",
    end_time: "16:00",
    event_type: :conference,
    cost: "$450",
    registration_url: "https://example.com/tech-retreat",
    user: liam,
    event_locations_attributes: [loc(region: :otago, city: "Queenstown")]
  },
  {
    title: "Palmerston North DevOps Meetup",
    description: "Bi-monthly DevOps meetup covering CI/CD pipelines, infrastructure as code, and monitoring. All experience levels welcome.",
    start_date: Date.current + 16.days,
    start_time: "18:00",
    end_time: "20:00",
    event_type: :meetup,
    cost: "Free",
    user: test_user,
    event_locations_attributes: [loc(region: :manawatu_whanganui, city: "Palmerston North")]
  },
  {
    title: "React & TypeScript Workshop",
    description: "Build a full-stack application with React and TypeScript. Covers hooks, state management, and API integration patterns.",
    start_date: Date.current + 35.days,
    start_time: "09:00",
    end_time: "17:00",
    event_type: :workshop,
    cost: "$95",
    user: sarah,
    event_locations_attributes: [loc(region: :auckland, city: "Auckland CBD")]
  },
  {
    title: "New Plymouth Tech Drinks",
    description: "Informal networking for Taranaki tech workers. No agenda, just good conversation and a chance to meet others in the local tech scene.",
    start_date: Date.current + 9.days,
    start_time: "17:00",
    end_time: "19:00",
    event_type: :networking,
    cost: "Free",
    user: james,
    event_locations_attributes: [loc(region: :taranaki, city: "New Plymouth")]
  },
  {
    title: "GovTech Hackathon Wellington",
    description: "Use open government data to build solutions for public good. Teams of 3-5 people. Mentors from government agencies available.",
    start_date: Date.current + 40.days,
    end_date: Date.current + 42.days,
    start_time: "09:00",
    event_type: :hackathon,
    cost: "Free",
    registration_url: "https://example.com/govtech-hack",
    user: aroha,
    event_locations_attributes: [loc(region: :wellington, city: "Wellington CBD")]
  },
  {
    title: "Mobile App Development Webinar",
    description: "Comparing React Native, Flutter, and native development for mobile apps. Pros, cons, and when to use each approach.",
    start_date: Date.current + 6.days,
    start_time: "13:00",
    end_time: "14:00",
    event_type: :webinar,
    cost: "Free",
    registration_url: "https://example.com/mobile-webinar",
    user: liam,
    event_locations_attributes: [loc(region: :online, city: "Online")]
  },
  {
    title: "Nelson Tech Community Meetup",
    description: "Monthly meetup for tech enthusiasts in the Nelson region. Lightning talks, project show-and-tell, and networking.",
    start_date: Date.current + 20.days,
    start_time: "18:00",
    end_time: "20:00",
    event_type: :meetup,
    cost: "Free",
    user: test_user,
    event_locations_attributes: [loc(region: :nelson, city: "Nelson")]
  }
]

future_events.each do |event_data|
  Event.create!(event_data)
  puts "  Created: #{event_data[:title]}"
end

# Approve 3 of the unapproved future events (aroha/liam's) so 15 total are approved, 5 remain pending
Event.upcoming.where(approved: false).limit(3).update_all(approved: true)
puts "  Approved 3 additional future events (15 approved, 5 pending)"

# Create past events
puts "Creating past events..."

past_events = [
  {
    title: "Auckland Tech Meetup - December",
    description: "End of year wrap-up meetup with lightning talks and a retrospective of the NZ tech scene in 2025.",
    start_date: Date.current - 45.days,
    start_time: "18:00",
    end_time: "20:00",
    event_type: :meetup,
    cost: "Free",
    user: test_user,
    event_locations_attributes: [loc(region: :auckland, city: "Auckland CBD")]
  },
  {
    title: "Christchurch Web Dev Workshop",
    description: "Full-day workshop on modern web development with HTML, CSS, and vanilla JavaScript.",
    start_date: Date.current - 30.days,
    start_time: "09:00",
    end_time: "17:00",
    event_type: :workshop,
    cost: "$60",
    user: james,
    event_locations_attributes: [loc(region: :canterbury, city: "Christchurch")]
  },
  {
    title: "Wellington Startup Weekend",
    description: "54-hour event where aspiring entrepreneurs pitched ideas, formed teams, and launched startups.",
    start_date: Date.current - 60.days,
    end_date: Date.current - 58.days,
    start_time: "18:00",
    event_type: :hackathon,
    cost: "$99",
    user: aroha,
    event_locations_attributes: [loc(region: :wellington, city: "Wellington CBD")]
  },
  {
    title: "API Design Best Practices Webinar",
    description: "Covered RESTful API design, versioning strategies, and documentation with OpenAPI/Swagger.",
    start_date: Date.current - 14.days,
    start_time: "12:00",
    end_time: "13:00",
    event_type: :webinar,
    cost: "Free",
    user: sarah,
    event_locations_attributes: [loc(region: :online, city: "Online")]
  },
  {
    title: "NZ Tech Awards Gala",
    description: "Annual celebration of excellence in New Zealand technology. Awards, dinner, and networking.",
    start_date: Date.current - 90.days,
    start_time: "18:00",
    end_time: "23:00",
    event_type: :conference,
    cost: "$175",
    user: liam,
    event_locations_attributes: [loc(region: :auckland, city: "Auckland CBD")]
  }
]

past_events.each do |event_data|
  Event.create!(event_data)
  puts "  Created: #{event_data[:title]}"
end

# Create email subscriptions
puts "Creating email subscriptions..."

subscriptions = [
  { email_address: "dev@example.com", region: :auckland },
  { email_address: "sarah@example.com", region: :wellington },
  { email_address: "james@example.com", region: :canterbury },
  { email_address: "aroha@example.com", region: :online },
  { email_address: "newsletter@example.com", region: :auckland }
]

subscriptions.each do |sub_data|
  EmailSubscription.create!(sub_data)
  puts "  Subscribed: #{sub_data[:email_address]} to #{sub_data[:region]}"
end

puts ""
puts "Done! Created:"
puts "  #{User.count} users"
puts "  #{Event.count} events (#{future_events.size} future, #{past_events.size} past)"
puts "  #{EmailSubscription.count} email subscriptions"
puts ""
puts "Login credentials (all users share the same password):"
puts "  Password: password123"
puts "  Emails: test@example.com, sarah@example.com, james@example.com, aroha@example.com, liam@example.com"
