# Clear existing data
puts "Clearing existing data..."
Event.destroy_all
User.destroy_all

# Create test user
puts "Creating test user..."
test_user = User.create!(
  email_address: "test@example.com",
  password: "password123",
  name: "Test User"
)

# Create sample events
puts "Creating sample events..."

events_data = [
  {
    title: "Auckland JavaScript Meetup",
    description: "Join us for an evening of JavaScript talks and networking. We'll have two speakers covering modern JS frameworks and best practices for async programming.",
    start_date: Date.current + 7.days,
    start_time: "18:00",
    end_time: "21:00",
    event_type: :meetup,
    region: :auckland,
    city: "Auckland CBD",
    address: "GridAKL, 12 Madden Street",
    cost: "Free"
  },
  {
    title: "Wellington Tech Conference 2025",
    description: "The biggest tech conference in the capital! Two days of talks, workshops, and networking with the best minds in NZ tech.",
    start_date: Date.current + 30.days,
    end_date: Date.current + 31.days,
    start_time: "09:00",
    end_time: "17:00",
    event_type: :conference,
    region: :wellington,
    city: "Wellington CBD",
    address: "Te Papa Museum",
    cost: "$199",
    registration_url: "https://example.com/register"
  },
  {
    title: "Christchurch Python Workshop",
    description: "A hands-on workshop for Python beginners. Learn the basics of Python programming in a friendly, supportive environment.",
    start_date: Date.current + 14.days,
    start_time: "10:00",
    end_time: "16:00",
    event_type: :workshop,
    region: :canterbury,
    city: "Christchurch",
    address: "University of Canterbury",
    cost: "$50"
  },
  {
    title: "Remote Work Webinar",
    description: "Tips and tricks for effective remote work. Join us online to learn from experienced remote workers.",
    start_date: Date.current + 3.days,
    start_time: "12:00",
    end_time: "13:00",
    event_type: :webinar,
    region: :online,
    city: "Online",
    cost: "Free",
    registration_url: "https://zoom.us/example"
  },
  {
    title: "Hamilton Hackathon",
    description: "48-hour hackathon! Build something amazing with fellow developers. Prizes for top projects!",
    start_date: Date.current + 45.days,
    end_date: Date.current + 47.days,
    start_time: "18:00",
    event_type: :hackathon,
    region: :waikato,
    city: "Hamilton",
    address: "Innovation Park, 10 Mill Street",
    cost: "$25"
  },
  {
    title: "Past Meetup Example",
    description: "This is a past event to demonstrate the past events page.",
    start_date: Date.current - 14.days,
    start_time: "18:00",
    end_time: "20:00",
    event_type: :meetup,
    region: :auckland,
    city: "Auckland CBD",
    cost: "Free"
  }
]

events_data.each do |event_data|
  Event.create!(event_data.merge(user: test_user))
  puts "  Created: #{event_data[:title]}"
end

puts "Done! Created #{User.count} user and #{Event.count} events."
puts ""
puts "Login credentials:"
puts "  Email: test@example.com"
puts "  Password: password123"
