require "test_helper"

class EventLocationTest < ActiveSupport::TestCase
  # -- Validations --

  test "valid location with region" do
    location = EventLocation.new(
      event: events(:approved_upcoming),
      region: :wellington,
      city: "Wellington CBD"
    )
    assert location.valid?
  end

  test "region is required" do
    location = EventLocation.new(event: events(:approved_upcoming), region: nil)
    assert_not location.valid?
    assert location.errors[:region].any?
  end

  # -- region_display --

  test "region_display returns Asia Pacific for apac" do
    location = EventLocation.new(region: :apac)
    assert_equal "Asia Pacific", location.region_display
  end

  test "region_display titleizes wellington" do
    location = EventLocation.new(region: :wellington)
    assert_equal "Wellington", location.region_display
  end

  test "region_display titleizes manawatu_whanganui" do
    location = EventLocation.new(region: :manawatu_whanganui)
    assert_equal "Manawatu Whanganui", location.region_display
  end

  test "region_display titleizes bay_of_plenty" do
    location = EventLocation.new(region: :bay_of_plenty)
    assert_equal "Bay Of Plenty", location.region_display
  end

  # -- full_display --

  test "full_display with city includes city and region" do
    location = EventLocation.new(region: :wellington, city: "Wellington CBD")
    assert_equal "Wellington CBD, Wellington", location.full_display
  end

  test "full_display without city returns just region display" do
    location = EventLocation.new(region: :wellington, city: nil)
    assert_equal "Wellington", location.full_display
  end

  test "full_display with blank city returns just region display" do
    location = EventLocation.new(region: :wellington, city: "")
    assert_equal "Wellington", location.full_display
  end

  # -- Default scope ordering --

  test "default scope orders by position ascending" do
    event = events(:approved_upcoming)
    # Add a second location with a lower position
    loc = event.event_locations.create!(region: :auckland, city: "Auckland CBD", position: -1)
    locations = event.event_locations.reload
    assert_equal loc, locations.first
  end

  # -- Fixture sanity --

  test "wellington_location belongs to approved_upcoming" do
    location = event_locations(:wellington_location)
    assert_equal events(:approved_upcoming), location.event
    assert location.region_wellington?
  end

  test "auckland_location belongs to past_event" do
    location = event_locations(:auckland_location)
    assert_equal events(:past_event), location.event
    assert location.region_auckland?
  end
end
