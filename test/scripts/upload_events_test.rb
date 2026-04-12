require "minitest/autorun"
require "csv"
require "json"
require "tmpdir"

# Stub ENV before loading the script
ENV["TECHEVENTS_API_TOKEN"] ||= "techevents_testtoken"

require_relative "../../scripts/upload_events"

class BuildEventJsonTest < Minitest::Test
  def make_row(overrides = {})
    defaults = {
      "TechEventsID" => "",
      "title" => "Test Event",
      "short_summary" => "A test",
      "description_markdowndescription_markdown" => "Some **markdown**",
      "start_date" => "2026-05-01",
      "end_date" => "",
      "start_time" => "09:00",
      "end_time" => "17:00",
      "cost" => "Free",
      "event_type" => "meetup",
      "registration_url" => "https://example.com",
      "region" => "auckland",
      "city" => "Auckland CBD",
      "address" => "123 Queen St",
      "source" => "Events in Aotearoa",
      "source_url" => "https://example.com/source",
      "organiser" => "Test Org",
      "event_mode" => "",
      "notes" => "",
      "ai_description" => "AI generated",
      "ai_updated" => "true"
    }
    CSV::Row.new(defaults.keys, defaults.merge(overrides).values)
  end

  def test_maps_direct_fields
    json = build_event_json(make_row)
    event = json["event"]

    assert_equal "Test Event", event["title"]
    assert_equal "A test", event["short_summary"]
    assert_equal "Some **markdown**", event["description_markdown"]
    assert_equal "2026-05-01", event["start_date"]
    assert_equal "09:00", event["start_time"]
    assert_equal "17:00", event["end_time"]
    assert_equal "Free", event["cost"]
    assert_equal "meetup", event["event_type"]
    assert_equal "https://example.com", event["registration_url"]
    assert_equal "123 Queen St", event["address"]
    assert_equal "Events in Aotearoa", event["source"]
    assert_equal "https://example.com/source", event["source_url"]
  end

  def test_builds_location_from_region_and_city
    json = build_event_json(make_row)
    locations = json["event"]["locations"]

    assert_equal 1, locations.length
    assert_equal "auckland", locations[0]["region"]
    assert_equal "Auckland CBD", locations[0]["city"]
  end

  def test_omits_empty_fields
    json = build_event_json(make_row("end_date" => "", "cost" => ""))
    event = json["event"]

    assert_nil event["end_date"]
    assert_nil event["cost"]
  end

  def test_omits_location_when_region_blank
    json = build_event_json(make_row("region" => "", "city" => ""))
    assert_nil json["event"]["locations"]
  end

  def test_location_without_city
    json = build_event_json(make_row("city" => ""))
    location = json["event"]["locations"][0]

    assert_equal "auckland", location["region"]
    refute location.key?("city")
  end

  def test_does_not_send_csv_only_fields
    json = build_event_json(make_row)
    event = json["event"]

    assert_nil event["organiser"]
    assert_nil event["event_mode"]
    assert_nil event["notes"]
    assert_nil event["ai_description"]
    assert_nil event["ai_updated"]
    assert_nil event["TechEventsID"]
  end
end

class FormatErrorTest < Minitest::Test
  def test_formats_validation_errors
    body = { "errors" => { "title" => [ "can't be blank" ], "start_date" => [ "can't be blank", "is invalid" ] } }
    result = format_error(422, body)

    assert_includes result, "title: can't be blank"
    assert_includes result, "start_date: can't be blank, is invalid"
  end

  def test_formats_single_error
    body = { "error" => "Unauthorized" }
    result = format_error(401, body)

    assert_equal "Unauthorized", result
  end

  def test_formats_unknown_body
    body = { "something" => "else" }
    result = format_error(500, body)

    assert_includes result, "HTTP 500"
  end
end
