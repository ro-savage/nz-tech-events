require "test_helper"

class EventsHelperTest < ActionView::TestCase
  include EventsHelper

  # ---------------------------------------------------------------------------
  # CITIES_BY_REGION constant
  # ---------------------------------------------------------------------------

  test "CITIES_BY_REGION contains all expected regions" do
    expected_regions = %w[
      northland auckland waikato bay_of_plenty gisborne hawkes_bay taranaki
      manawatu_whanganui wellington tasman nelson marlborough west_coast
      canterbury otago southland apac online
    ]

    expected_regions.each do |region|
      assert CITIES_BY_REGION.key?(region),
        "Expected CITIES_BY_REGION to include '#{region}'"
    end
  end

  test "CITIES_BY_REGION online region has only Online" do
    assert_equal ["Online"], CITIES_BY_REGION["online"]
  end

  test "CITIES_BY_REGION auckland has expected cities" do
    expected = [
      "Auckland CBD", "North Shore", "West Auckland",
      "South Auckland", "East Auckland", "Other"
    ]
    assert_equal expected, CITIES_BY_REGION["auckland"]
  end

  test "CITIES_BY_REGION every region ends with Other or equivalent" do
    CITIES_BY_REGION.each do |region, cities|
      next if region == "online"

      last_city = cities.last
      assert last_city.start_with?("Other"),
        "Expected last city in '#{region}' to start with 'Other', got '#{last_city}'"
    end
  end

  # ---------------------------------------------------------------------------
  # cities_for_region
  # ---------------------------------------------------------------------------

  test "cities_for_region returns cities for a valid region string" do
    cities = cities_for_region("auckland")
    assert_includes cities, "Auckland CBD"
    assert_includes cities, "North Shore"
  end

  test "cities_for_region accepts a symbol and returns cities" do
    cities = cities_for_region(:wellington)
    assert_includes cities, "Wellington CBD"
  end

  test "cities_for_region returns empty array for unknown region" do
    assert_equal [], cities_for_region("atlantis")
  end

  test "cities_for_region returns empty array for nil" do
    assert_equal [], cities_for_region(nil)
  end

  # ---------------------------------------------------------------------------
  # cities_json
  # ---------------------------------------------------------------------------

  test "cities_json returns a valid JSON string" do
    json = cities_json
    parsed = JSON.parse(json)
    assert_kind_of Hash, parsed
  end

  test "cities_json contains expected structure" do
    parsed = JSON.parse(cities_json)
    assert parsed.key?("auckland")
    assert_includes parsed["auckland"], "Auckland CBD"
    assert_equal ["Online"], parsed["online"]
  end

  # ---------------------------------------------------------------------------
  # region_options
  # ---------------------------------------------------------------------------

  test "region_options returns array of label-value pairs" do
    options = region_options
    assert_kind_of Array, options

    options.each do |option|
      assert_equal 2, option.length, "Each option should be a [label, value] pair"
      label, value = option
      assert_kind_of String, label
      assert_kind_of String, value
    end
  end

  test "region_options includes Asia Pacific label for apac" do
    options = region_options
    apac_option = options.find { |_, v| v == "apac" }
    assert_not_nil apac_option, "Expected to find an option with value 'apac'"
    assert_equal "Asia Pacific", apac_option.first
  end

  test "region_options covers all defined regions" do
    option_values = region_options.map(&:last)
    Event.regions.keys.each do |region_key|
      assert_includes option_values, region_key,
        "Expected region_options to include '#{region_key}'"
    end
  end

  test "region_options titleizes region names" do
    options = region_options
    auckland_option = options.find { |_, v| v == "auckland" }
    assert_equal "Auckland", auckland_option.first
  end

  # ---------------------------------------------------------------------------
  # event_type_options
  # ---------------------------------------------------------------------------

  test "event_type_options returns array of label-value pairs" do
    options = event_type_options
    assert_kind_of Array, options

    options.each do |option|
      assert_equal 2, option.length
      label, value = option
      assert_kind_of String, label
      assert_kind_of String, value
    end
  end

  test "event_type_options follows EVENT_TYPE_DROPDOWN_ORDER" do
    options = event_type_options
    values = options.map(&:last)

    EVENT_TYPE_DROPDOWN_ORDER.each_with_index do |type, index|
      assert_equal type, values[index],
        "Expected '#{type}' at position #{index}, got '#{values[index]}'"
    end
  end

  test "event_type_options covers all defined event types" do
    option_values = event_type_options.map(&:last)
    Event.event_types.keys.each do |type_key|
      assert_includes option_values, type_key,
        "Expected event_type_options to include '#{type_key}'"
    end
  end

  test "event_type_options titleizes labels" do
    options = event_type_options
    conference_option = options.find { |_, v| v == "conference" }
    assert_equal "Conference", conference_option.first
  end

  # ---------------------------------------------------------------------------
  # month_filter_options
  # ---------------------------------------------------------------------------

  test "month_filter_options returns 13 options" do
    options = month_filter_options
    assert_equal 13, options.length
  end

  test "month_filter_options starts with current month" do
    options = month_filter_options
    label, value = options.first
    assert_equal Date.current.strftime("%B %Y"), label
    assert_equal Date.current.strftime("%Y-%m"), value
  end

  test "month_filter_options has label-value pairs in expected format" do
    options = month_filter_options
    options.each do |label, value|
      assert_match(/\A[A-Z][a-z]+ \d{4}\z/, label,
        "Label '#{label}' should be like 'January 2026'")
      assert_match(/\A\d{4}-\d{2}\z/, value,
        "Value '#{value}' should be like '2026-01'")
    end
  end

  # ---------------------------------------------------------------------------
  # event_type_badge_class
  # ---------------------------------------------------------------------------

  test "event_type_badge_class returns correct class string" do
    assert_equal "badge badge-meetup", event_type_badge_class("meetup")
    assert_equal "badge badge-conference", event_type_badge_class("conference")
    assert_equal "badge badge-workshop", event_type_badge_class("workshop")
  end

  # ---------------------------------------------------------------------------
  # google_calendar_url
  # ---------------------------------------------------------------------------

  test "google_calendar_url returns URL with correct base" do
    event = events(:approved_upcoming)
    url = google_calendar_url(event)
    assert url.start_with?("https://calendar.google.com/calendar/render?")
  end

  test "google_calendar_url includes event title URL-encoded" do
    event = events(:approved_upcoming)
    url = google_calendar_url(event)
    assert_includes url, "text=Wellington+Ruby+Meetup"
  end

  test "google_calendar_url handles single-day event with start and end time" do
    event = events(:approved_upcoming)
    url = google_calendar_url(event)

    assert_includes url, "dates="
    # Should contain a date range separated by /
    dates_match = url.match(/dates=([^&]+)/)
    assert dates_match, "Expected URL to contain dates parameter"
    dates_value = CGI.unescape(dates_match[1])
    assert_match(%r{\d{8}T\d{6}Z/\d{8}T\d{6}Z}, dates_value)
  end

  test "google_calendar_url handles multi-day event" do
    event = events(:multi_day_event)
    url = google_calendar_url(event)

    dates_match = url.match(/dates=([^&]+)/)
    assert dates_match
    dates_value = CGI.unescape(dates_match[1])
    start_part, end_part = dates_value.split("/")

    # End date should be later than start date for multi-day event
    assert start_part < end_part,
      "Expected end time (#{end_part}) to be after start time (#{start_part})"
  end

  test "google_calendar_url handles event with no start_time as all-day" do
    event = events(:approved_upcoming)
    event.start_time = nil
    url = google_calendar_url(event)
    assert_includes url, "dates="
    # All-day events default to 9:00-17:00 NZ time
    assert url.include?("ctz=Pacific")
  end

  test "google_calendar_url handles event with start_time but no end_time" do
    event = events(:approved_upcoming)
    event.end_time = nil
    url = google_calendar_url(event)
    assert_includes url, "dates="
    # Should default to 2 hours after start
  end

  test "google_calendar_url includes timezone parameter" do
    event = events(:approved_upcoming)
    url = google_calendar_url(event)
    assert_includes url, "ctz=Pacific"
  end

  # ---------------------------------------------------------------------------
  # ical_content
  # ---------------------------------------------------------------------------

  test "ical_content begins with BEGIN:VCALENDAR" do
    event = events(:approved_upcoming)
    content = ical_content(event)
    assert content.start_with?("BEGIN:VCALENDAR")
  end

  test "ical_content ends with END:VCALENDAR" do
    event = events(:approved_upcoming)
    content = ical_content(event)
    assert content.strip.end_with?("END:VCALENDAR")
  end

  test "ical_content contains VEVENT block" do
    event = events(:approved_upcoming)
    content = ical_content(event)
    assert_includes content, "BEGIN:VEVENT"
    assert_includes content, "END:VEVENT"
  end

  test "ical_content includes event title as SUMMARY" do
    event = events(:approved_upcoming)
    content = ical_content(event)
    assert_includes content, "SUMMARY:Wellington Ruby Meetup"
  end

  test "ical_content includes URL when registration_url is present" do
    event = events(:approved_upcoming)
    assert event.registration_url.present?,
      "Fixture should have a registration_url"
    content = ical_content(event)
    assert_includes content, "URL:https://example.com/register"
  end

  test "ical_content omits URL when registration_url is blank" do
    event = events(:approved_upcoming)
    event.registration_url = nil
    content = ical_content(event)
    refute_includes content, "URL:"
  end

  test "ical_content escapes commas in title" do
    event = events(:approved_upcoming)
    event.title = "Meet, Greet"
    content = ical_content(event)
    assert_includes content, 'SUMMARY:Meet\, Greet'
  end

  test "ical_content escapes semicolons in title" do
    event = events(:approved_upcoming)
    event.title = "Learn; Code"
    content = ical_content(event)
    assert_includes content, 'SUMMARY:Learn\; Code'
  end

  test "ical_content uses CRLF line endings" do
    event = events(:approved_upcoming)
    content = ical_content(event)
    # iCal spec requires \r\n
    assert_includes content, "\r\n"
  end

  test "ical_content includes PRODID" do
    event = events(:approved_upcoming)
    content = ical_content(event)
    assert_includes content, "PRODID:-//NZ Tech Events//techevents.co.nz//EN"
  end

  test "ical_content includes timezone block" do
    event = events(:approved_upcoming)
    content = ical_content(event)
    assert_includes content, "BEGIN:VTIMEZONE"
    assert_includes content, "TZID:Pacific/Auckland"
    assert_includes content, "END:VTIMEZONE"
  end

  test "ical_content includes unique UID" do
    event = events(:approved_upcoming)
    content = ical_content(event)
    assert_includes content, "UID:event-#{event.id}@techevents.co.nz"
  end
end
