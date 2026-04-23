require "test_helper"

class EventJsonLdTest < ActionView::TestCase
  include EventsHelper

  test "json-ld contains required schema.org fields" do
    event = events(:approved_upcoming)
    json = JSON.parse(event_json_ld(event))

    assert_equal "https://schema.org", json["@context"]
    assert_includes json["@type"], "Event"
    assert_equal event.title, json["name"]
    assert json["startDate"].present?, "startDate must be present"
    assert json["description"].present?, "description must be present"
    assert_equal "https://schema.org/EventScheduled", json["eventStatus"]
  end

  test "json-ld maps event types to schema.org types" do
    event = events(:approved_upcoming)
    json = JSON.parse(event_json_ld(event))

    # approved_upcoming is a meetup (event_type: 1) -> SocialEvent
    assert_equal "SocialEvent", json["@type"]
  end

  test "json-ld maps conference to BusinessEvent" do
    event = events(:paid_event)
    json = JSON.parse(event_json_ld(event))

    # paid_event is a conference (event_type: 0)
    assert_equal "BusinessEvent", json["@type"]
  end

  test "json-ld maps workshop to EducationEvent" do
    event = events(:multi_day_event)
    json = JSON.parse(event_json_ld(event))

    # multi_day_event is a workshop (event_type: 2)
    assert_equal "EducationEvent", json["@type"]
  end

  test "free event has offer with price zero" do
    event = events(:free_event)
    json = JSON.parse(event_json_ld(event))

    assert_equal "Offer", json["offers"]["@type"]
    assert_equal "0", json["offers"]["price"]
    assert_equal "NZD", json["offers"]["priceCurrency"]
  end

  test "paid event has offer with numeric price parsed from cost" do
    event = events(:paid_event)
    json = JSON.parse(event_json_ld(event))

    # paid_event cost is "$50"; Schema.org requires numeric-only price
    assert_equal "Offer", json["offers"]["@type"]
    assert_equal "50", json["offers"]["price"]
    assert_equal "NZD", json["offers"]["priceCurrency"]
  end

  test "event with non-numeric cost omits offers" do
    event = events(:paid_event)
    event.cost = "Koha"
    json = JSON.parse(event_json_ld(event))

    assert_nil json["offers"]
  end

  test "offer includes url when event has registration_url" do
    event = events(:paid_event)
    json = JSON.parse(event_json_ld(event))

    assert_equal event.registration_url, json["offers"]["url"]
  end

  test "offer omits url when event has no registration_url" do
    event = events(:organiser_event)
    json = JSON.parse(event_json_ld(event))

    assert_nil json["offers"]["url"]
  end

  test "online event has OnlineEventAttendanceMode" do
    event = events(:online_event)
    json = JSON.parse(event_json_ld(event))

    assert_equal "https://schema.org/OnlineEventAttendanceMode",
                 json["eventAttendanceMode"]
  end

  test "online event has VirtualLocation" do
    event = events(:online_event)
    json = JSON.parse(event_json_ld(event))

    assert_equal "VirtualLocation", json["location"]["@type"]
    assert_equal event.registration_url, json["location"]["url"]
  end

  test "online event without registration_url omits location" do
    event = events(:online_event)
    event.registration_url = nil
    json = JSON.parse(event_json_ld(event))

    assert_nil json["location"]
  end

  test "event without any location data omits location and attendance mode" do
    event = events(:organiser_event)
    event.event_locations.destroy_all
    event.address = nil
    event.reload
    json = JSON.parse(event_json_ld(event))

    assert_nil json["location"]
    assert_nil json["eventAttendanceMode"]
  end

  test "offline event has OfflineEventAttendanceMode" do
    event = events(:approved_upcoming)
    json = JSON.parse(event_json_ld(event))

    assert_equal "https://schema.org/OfflineEventAttendanceMode",
                 json["eventAttendanceMode"]
  end

  test "offline event has Place location with region and city" do
    event = events(:approved_upcoming)
    json = JSON.parse(event_json_ld(event))

    assert_equal "Place", json["location"]["@type"]
    assert_includes json["location"]["name"], "Wellington CBD"
  end

  test "multi-day event has endDate" do
    event = events(:multi_day_event)
    json = JSON.parse(event_json_ld(event))

    assert json["endDate"].present?, "endDate must be present for multi-day events"
  end

  test "event without end_date or end_time has no endDate" do
    event = events(:approved_upcoming)
    event.end_date = nil
    event.end_time = nil
    json = JSON.parse(event_json_ld(event))

    assert_nil json["endDate"]
  end

  test "date-only event (no start_time) emits startDate without time component" do
    event = events(:approved_upcoming)
    event.start_time = nil
    event.end_time = nil
    json = JSON.parse(event_json_ld(event))

    refute_match(/T/, json["startDate"], "startDate without time should not include T separator")
  end

  test "startDate includes time when event has start_time" do
    event = events(:approved_upcoming)
    json = JSON.parse(event_json_ld(event))

    # Should be ISO 8601 with time component (contains T)
    assert_match(/T/, json["startDate"], "startDate with time should include T separator")
  end

  test "event with registration_url includes url field" do
    event = events(:approved_upcoming)
    json = JSON.parse(event_json_ld(event))

    assert_equal event.registration_url, json["url"]
  end

  test "json-ld output is valid JSON" do
    events_to_test = [
      :approved_upcoming, :multi_day_event, :free_event,
      :paid_event, :online_event
    ]

    events_to_test.each do |fixture_name|
      event = events(fixture_name)
      json = event_json_ld(event)
      parsed = JSON.parse(json)
      assert parsed.is_a?(Hash), "#{fixture_name} should produce a valid JSON object"
    end
  end
end
