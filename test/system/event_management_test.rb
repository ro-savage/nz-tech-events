require "application_system_test_case"

class EventManagementTest < ApplicationSystemTestCase
  setup do
    @regular_user = users(:regular)
  end

  test "create a new event as regular user" do
    sign_in_as(@regular_user)

    visit new_event_path

    assert_text "Event Details"

    fill_in "event_title", with: "System Test Meetup"
    select "Meetup", from: "event_event_type"

    find("trix-editor").click
    find("trix-editor").send_keys("A great meetup for system testing enthusiasts")

    start_date = 30.days.from_now.to_date
    execute_script(
      "document.querySelector('input[name=\"event[dates][0][start_date]\"]').value = arguments[0]",
      start_date.strftime("%Y-%m-%d")
    )
    execute_script(
      "document.querySelector('input[name=\"event[dates][0][start_time]\"]').value = '18:00'"
    )
    execute_script(
      "document.querySelector('input[name=\"event[dates][0][end_time]\"]').value = '20:00'"
    )

    select "Wellington", from: "event_event_locations_attributes_0_region"

    fill_in "event_cost", with: "Free"

    click_button "Create Event"

    assert_text "Event created"
    assert_text "System Test Meetup"
  end

  test "visit my events page shows created events" do
    sign_in_as(@regular_user)

    visit my_events_events_path

    assert_text "My Events"
    assert_text "Wellington Ruby Meetup"
  end

  test "edit an event and update title" do
    sign_in_as(@regular_user)
    event = events(:approved_upcoming)

    visit edit_event_path(event)

    fill_in "event_title", with: "Updated Ruby Meetup"
    click_button "Update Event"

    assert_text "Event updated successfully"
    assert_text "Updated Ruby Meetup"
  end

  test "delete an event" do
    sign_in_as(@regular_user)
    event = events(:approved_upcoming)

    visit event_path(event)

    accept_confirm "Are you sure you want to delete this event?" do
      click_button "Delete"
    end

    assert_text "Event deleted successfully"
  end
end
