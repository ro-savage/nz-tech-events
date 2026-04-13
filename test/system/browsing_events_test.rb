require "application_system_test_case"

class BrowsingEventsTest < ApplicationSystemTestCase
  test "homepage displays upcoming approved events" do
    visit root_path

    assert_text "Wellington Ruby Meetup"
    assert_text "Tech Networking Evening"
    assert_no_text "Startup Hackathon" # unapproved
  end

  test "past events page displays past events" do
    visit past_events_path

    assert_text "NZ Tech Conference 2025"
    assert_no_text "Wellington Ruby Meetup" # upcoming, not past
  end

  test "event detail page shows title, date, and location" do
    event = events(:approved_upcoming)
    visit event_path(event)

    assert_text event.title
    assert_text event.formatted_date
    assert_text "Wellington CBD"
    assert_text "Register / Get Tickets"
  end

  test "about page loads successfully" do
    visit about_path

    assert_selector "h1"
  end

  test "API docs page loads successfully" do
    visit api_docs_path

    assert_text "API"
  end
end
