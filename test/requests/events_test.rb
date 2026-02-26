require "test_helper"

class EventsTest < ActionDispatch::IntegrationTest
  # ── INDEX (GET /) ──────────────────────────────────────────────────

  test "index renders successfully for anonymous user" do
    get root_path
    assert_response :success
  end

  test "index only shows approved upcoming events" do
    get root_path
    assert_response :success

    # Approved upcoming events should appear
    assert_match events(:approved_upcoming).title, response.body
    assert_match events(:multi_day_event).title, response.body
    assert_match events(:free_event).title, response.body
    assert_match events(:paid_event).title, response.body

    # Unapproved and past events should NOT appear
    assert_no_match(/#{Regexp.escape(events(:unapproved_upcoming).title)}/, response.body)
    assert_no_match(/#{Regexp.escape(events(:past_event).title)}/, response.body)
  end

  test "index filters by region" do
    get root_path, params: { region: "wellington" }
    assert_response :success
    assert_match events(:approved_upcoming).title, response.body
  end

  test "index filters by city" do
    get root_path, params: { city: "Christchurch" }
    assert_response :success
    assert_match events(:multi_day_event).title, response.body
  end

  # ── PAST (GET /past) ──────────────────────────────────────────────

  test "past renders successfully for anonymous user" do
    get past_events_path
    assert_response :success
  end

  test "past shows past events" do
    get past_events_path
    assert_response :success
    assert_match events(:past_event).title, response.body
  end

  # ── SHOW (GET /events/:id) ────────────────────────────────────────

  test "show renders approved event without error" do
    get event_path(events(:approved_upcoming))
    assert_response :success
  end

  test "show renders event with all fields (multi-day) without error" do
    get event_path(events(:multi_day_event))
    assert_response :success
  end

  test "show renders free event without error" do
    get event_path(events(:free_event))
    assert_response :success
  end

  test "show renders paid event without error" do
    get event_path(events(:paid_event))
    assert_response :success
  end

  test "show renders past event without error" do
    get event_path(events(:past_event))
    assert_response :success
  end

  test "show displays event details" do
    event = events(:approved_upcoming)
    get event_path(event)
    assert_response :success
    assert_match event.title, response.body
  end

  test "show returns 404 for nonexistent event" do
    get event_path(id: 999999)
    assert_response :not_found
  end

  # ── NEW (GET /events/new) ─────────────────────────────────────────

  test "new redirects to login if not authenticated" do
    get new_event_path
    assert_response :redirect
    follow_redirect!
    assert_match(/login/i, request.path)
  end

  test "new returns 200 if authenticated" do
    sign_in_as users(:regular)
    get new_event_path
    assert_response :success
  end

  test "new redirects with alert when user is rate limited" do
    user = users(:regular)
    sign_in_as user

    # Create enough events to hit the rate limit (user may already have some from fixtures)
    existing_count = user.events_created_in_last_24_hours
    (10 - existing_count).times do |i|
      Event.insert({
        title: "Rate limit event #{i}",
        start_date: 1.week.from_now,
        event_type: 1,
        user_id: user.id,
        created_at: Time.current,
        updated_at: Time.current
      })
    end

    get new_event_path
    assert_response :redirect
    follow_redirect!
    assert_match(/10 events/, response.body)
  end

  # ── CREATE (POST /events) ─────────────────────────────────────────

  test "create redirects to login if not authenticated" do
    post events_path, params: { event: { title: "Test" } }
    assert_response :redirect
  end

  test "create creates event with valid params and redirects to show" do
    sign_in_as users(:regular)

    assert_difference "Event.count", 1 do
      post events_path, params: {
        event: {
          title: "New Meetup Event",
          start_date: 1.week.from_now,
          event_type: "meetup",
          description: "A great new meetup for developers",
          event_locations_attributes: {
            "0" => { region: "wellington", city: "Wellington CBD" }
          }
        }
      }
    end

    new_event = Event.last
    assert_redirected_to event_path(new_event)
  end

  test "create sets event as unapproved for regular user" do
    sign_in_as users(:regular)

    post events_path, params: {
      event: {
        title: "Regular User Event",
        start_date: 1.week.from_now,
        event_type: "meetup",
        description: "Description text here",
        event_locations_attributes: {
          "0" => { region: "auckland", city: "Auckland CBD" }
        }
      }
    }

    assert_not Event.last.approved?
  end

  test "create sets event as approved for organiser" do
    sign_in_as users(:organiser)

    post events_path, params: {
      event: {
        title: "Organiser Event",
        start_date: 1.week.from_now,
        event_type: "meetup",
        description: "Description text here",
        event_locations_attributes: {
          "0" => { region: "wellington", city: "Wellington CBD" }
        }
      }
    }

    assert Event.last.approved?
  end

  test "create sets event as approved for admin" do
    sign_in_as users(:admin)

    post events_path, params: {
      event: {
        title: "Admin Event",
        start_date: 1.week.from_now,
        event_type: "meetup",
        description: "Description text here",
        event_locations_attributes: {
          "0" => { region: "wellington", city: "Wellington CBD" }
        }
      }
    }

    assert Event.last.approved?
  end

  test "create renders errors with invalid params - missing title" do
    sign_in_as users(:regular)

    assert_no_difference "Event.count" do
      post events_path, params: {
        event: {
          title: "",
          start_date: 1.week.from_now,
          event_type: "meetup",
          description: "Description",
          event_locations_attributes: {
            "0" => { region: "wellington", city: "Wellington CBD" }
          }
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "create renders errors with invalid params - no location" do
    sign_in_as users(:regular)

    assert_no_difference "Event.count" do
      post events_path, params: {
        event: {
          title: "Event Without Location",
          start_date: 1.week.from_now,
          event_type: "meetup",
          description: "Description"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  # ── EDIT (GET /events/:id/edit) ───────────────────────────────────

  test "edit redirects to login if not authenticated" do
    get edit_event_path(events(:approved_upcoming))
    assert_response :redirect
  end

  test "edit returns 200 for event owner" do
    sign_in_as users(:regular)
    get edit_event_path(events(:approved_upcoming))
    assert_response :success
  end

  test "edit returns 200 for admin" do
    sign_in_as users(:admin)
    get edit_event_path(events(:approved_upcoming))
    assert_response :success
  end

  test "edit redirects non-owner with alert" do
    sign_in_as users(:organiser)
    get edit_event_path(events(:approved_upcoming))
    assert_response :redirect
    follow_redirect!
    assert_match(/not authorized/i, flash[:alert])
  end

  # ── UPDATE (PATCH /events/:id) ────────────────────────────────────

  test "update redirects to login if not authenticated" do
    patch event_path(events(:approved_upcoming)), params: { event: { title: "Updated" } }
    assert_response :redirect
  end

  test "update updates event for owner and redirects to show" do
    sign_in_as users(:regular)
    event = events(:approved_upcoming)

    patch event_path(event), params: { event: { title: "Updated Title" } }
    assert_redirected_to event_path(event)

    event.reload
    assert_equal "Updated Title", event.title
  end

  test "update updates event for admin" do
    sign_in_as users(:admin)
    event = events(:approved_upcoming)

    patch event_path(event), params: { event: { title: "Admin Updated" } }
    assert_redirected_to event_path(event)

    event.reload
    assert_equal "Admin Updated", event.title
  end

  test "update redirects non-owner with alert" do
    sign_in_as users(:organiser)
    event = events(:approved_upcoming)

    patch event_path(event), params: { event: { title: "Unauthorized Update" } }
    assert_response :redirect
    follow_redirect!
    assert_match(/not authorized/i, flash[:alert])
  end

  test "update renders errors with invalid params" do
    sign_in_as users(:regular)
    event = events(:approved_upcoming)

    patch event_path(event), params: { event: { title: "" } }
    assert_response :unprocessable_entity
  end

  # ── DESTROY (DELETE /events/:id) ──────────────────────────────────

  test "destroy redirects to login if not authenticated" do
    delete event_path(events(:approved_upcoming))
    assert_response :redirect
  end

  test "destroy destroys event for owner and redirects to root" do
    sign_in_as users(:regular)
    event = events(:approved_upcoming)

    assert_difference "Event.count", -1 do
      delete event_path(event)
    end

    assert_redirected_to root_path
  end

  test "destroy destroys event for admin" do
    sign_in_as users(:admin)
    event = events(:approved_upcoming)

    assert_difference "Event.count", -1 do
      delete event_path(event)
    end

    assert_redirected_to root_path
  end

  test "destroy redirects non-owner with alert" do
    sign_in_as users(:organiser)
    event = events(:approved_upcoming)

    assert_no_difference "Event.count" do
      delete event_path(event)
    end

    assert_response :redirect
    follow_redirect!
    assert_match(/not authorized/i, flash[:alert])
  end

  # ── MY_EVENTS (GET /events/my_events) ─────────────────────────────

  test "my_events redirects to login if not authenticated" do
    get my_events_events_path
    assert_response :redirect
  end

  test "my_events returns 200 for authenticated user" do
    sign_in_as users(:regular)
    get my_events_events_path
    assert_response :success
  end

  test "my_events shows user own events" do
    sign_in_as users(:regular)
    get my_events_events_path
    assert_response :success
    assert_match events(:approved_upcoming).title, response.body
  end

  # ── ICAL (GET /events/:id/ical) ───────────────────────────────────

  test "ical returns a calendar file" do
    get ical_event_path(events(:approved_upcoming))
    assert_response :success
    assert_match "calendar", response.content_type
  end

  test "ical returns valid ical content" do
    get ical_event_path(events(:approved_upcoming))
    assert_response :success
    assert_match "BEGIN:VCALENDAR", response.body
    assert_match "BEGIN:VEVENT", response.body
  end

  test "ical works for multi-day event" do
    get ical_event_path(events(:multi_day_event))
    assert_response :success
    assert_match "calendar", response.content_type
  end
end
