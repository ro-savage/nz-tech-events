require "test_helper"

class EventTest < ActiveSupport::TestCase
  # Helper to build a valid event for a user
  def build_valid_event(user, overrides = {})
    event = user.events.build({
      title: "Test Event",
      start_date: 1.week.from_now,
      event_type: :meetup
    }.merge(overrides))
    event.description = "Test description for this event"
    event.event_locations.build(region: :wellington, city: "Wellington CBD")
    event
  end

  # ========== Validations ==========

  test "valid event with all required fields" do
    event = build_valid_event(users(:regular))
    assert event.valid?
  end

  test "title is required" do
    event = build_valid_event(users(:regular), title: nil)
    assert_not event.valid?
    assert event.errors[:title].any?
  end

  test "title max length is 200 characters" do
    event = build_valid_event(users(:regular), title: "x" * 201)
    assert_not event.valid?
    assert event.errors[:title].any?
  end

  test "title of exactly 200 characters is valid" do
    event = build_valid_event(users(:regular), title: "x" * 200)
    assert event.valid?
  end

  test "start_date is required" do
    event = build_valid_event(users(:regular), start_date: nil)
    assert_not event.valid?
    assert event.errors[:start_date].any?
  end

  test "event_type is required" do
    event = users(:regular).events.build(title: "No type", start_date: 1.week.from_now)
    event.description = "Test"
    event.event_locations.build(region: :wellington, city: "Wellington CBD")
    event.event_type = nil
    assert_not event.valid?
    assert event.errors[:event_type].any?
  end

  test "description is required" do
    event = users(:regular).events.build(
      title: "No desc",
      start_date: 1.week.from_now,
      event_type: :meetup
    )
    event.event_locations.build(region: :wellington, city: "Wellington CBD")
    # Don't set description
    assert_not event.valid?
    assert event.errors[:description].any?
  end

  # -- at_least_one_location validation --

  test "event without locations is invalid" do
    event = users(:regular).events.build(
      title: "No location",
      start_date: 1.week.from_now,
      event_type: :meetup
    )
    event.description = "Test"
    # No event_locations built
    assert_not event.valid?
    assert event.errors[:base].any? { |e| e.include?("location") }
  end

  test "event with a location marked for destruction and no others is invalid" do
    event = events(:approved_upcoming)
    event.event_locations.each { |loc| loc.mark_for_destruction }
    assert_not event.valid?
    assert event.errors[:base].any? { |e| e.include?("location") }
  end

  # -- end_date_after_start_date validation --

  test "end_date before start_date is invalid" do
    event = build_valid_event(users(:regular),
      start_date: Date.current + 10,
      end_date: Date.current + 5
    )
    assert_not event.valid?
    assert_includes event.errors[:end_date], "must be after start date"
  end

  test "end_date same as start_date is valid" do
    event = build_valid_event(users(:regular),
      start_date: Date.current + 10,
      end_date: Date.current + 10
    )
    assert event.valid?
  end

  test "end_date after start_date is valid" do
    event = build_valid_event(users(:regular),
      start_date: Date.current + 10,
      end_date: Date.current + 15
    )
    assert event.valid?
  end

  test "nil end_date is valid" do
    event = build_valid_event(users(:regular), end_date: nil)
    assert event.valid?
  end

  # -- user_within_rate_limit validation (on create) --

  test "admin user can create event even at rate limit" do
    admin = users(:admin)
    10.times do |i|
      e = admin.events.build(title: "Flood #{i}", start_date: 1.week.from_now, event_type: :meetup)
      e.description = "Test"
      e.event_locations.build(region: :wellington, city: "Wellington CBD")
      e.save!(validate: false)
      e.update_column(:created_at, 1.hour.ago)
    end
    event = build_valid_event(admin)
    assert event.valid?
  end

  test "organiser can create event even at rate limit" do
    organiser = users(:organiser)
    10.times do |i|
      e = organiser.events.build(title: "Flood #{i}", start_date: 1.week.from_now, event_type: :meetup)
      e.description = "Test"
      e.event_locations.build(region: :wellington, city: "Wellington CBD")
      e.save!(validate: false)
      e.update_column(:created_at, 1.hour.ago)
    end
    event = build_valid_event(organiser)
    assert event.valid?
  end

  test "regular user cannot create event when at rate limit" do
    user = users(:regular)
    10.times do |i|
      e = user.events.build(title: "Flood #{i}", start_date: 1.week.from_now, event_type: :meetup)
      e.description = "Test"
      e.event_locations.build(region: :wellington, city: "Wellington CBD")
      e.save!(validate: false)
      e.update_column(:created_at, 1.hour.ago)
    end
    event = build_valid_event(user)
    assert_not event.valid?
    assert event.errors[:base].any? { |e| e.include?("10 events") }
  end

  # ========== Callback: set_approval_status ==========

  test "event by admin is auto-approved on create" do
    event = build_valid_event(users(:admin))
    event.save!
    assert event.approved?
  end

  test "event by approved organiser is auto-approved on create" do
    event = build_valid_event(users(:organiser))
    event.save!
    assert event.approved?
  end

  test "event by regular user is not auto-approved on create" do
    event = build_valid_event(users(:regular))
    event.save!
    assert_not event.approved?
  end

  # ========== Scopes ==========

  test "upcoming scope returns events with start_date >= today in ASC order" do
    upcoming = Event.upcoming
    assert upcoming.all? { |e| e.start_date >= Date.current }
    dates = upcoming.map(&:start_date)
    assert_equal dates, dates.sort
  end

  test "upcoming scope does not include past events" do
    past = events(:past_event)
    assert_not_includes Event.upcoming, past
  end

  test "past scope returns events with start_date < today in DESC order" do
    past = Event.past
    assert past.all? { |e| e.start_date < Date.current }
    dates = past.map(&:start_date)
    assert_equal dates, dates.sort.reverse
  end

  test "past scope does not include upcoming events" do
    upcoming = events(:approved_upcoming)
    assert_not_includes Event.past, upcoming
  end

  test "approved scope filters by approved true" do
    approved = Event.approved
    assert approved.all?(&:approved?)
    assert_includes approved, events(:approved_upcoming)
    assert_not_includes approved, events(:unapproved_upcoming)
  end

  test "pending_approval scope filters by approved false" do
    pending = Event.pending_approval
    assert pending.all? { |e| !e.approved? }
    assert_includes pending, events(:unapproved_upcoming)
    assert_not_includes pending, events(:approved_upcoming)
  end

  test "by_region scope filters via event_locations" do
    wellington_events = Event.by_region("wellington")
    assert_includes wellington_events, events(:approved_upcoming)
    # past_event has auckland location, should not appear
    assert_not_includes wellington_events, events(:past_event)
  end

  test "by_region scope returns all when blank" do
    assert_equal Event.all.count, Event.by_region("").count
    assert_equal Event.all.count, Event.by_region(nil).count
  end

  test "by_event_type scope filters correctly" do
    meetups = Event.by_event_type("meetup")
    assert meetups.all? { |e| e.event_type_meetup? }
    assert_includes meetups, events(:approved_upcoming)
  end

  test "by_event_type returns all when blank" do
    assert_equal Event.all.count, Event.by_event_type("").count
    assert_equal Event.all.count, Event.by_event_type(nil).count
  end

  # ========== Instance Methods ==========

  # -- owned_by? --

  test "owned_by? returns true for the owner" do
    event = events(:approved_upcoming)
    assert event.owned_by?(users(:regular))
  end

  test "owned_by? returns false for different user" do
    event = events(:approved_upcoming)
    assert_not event.owned_by?(users(:admin))
  end

  test "owned_by? returns false for nil" do
    event = events(:approved_upcoming)
    assert_not event.owned_by?(nil)
  end

  # -- editable_by? --

  test "editable_by? returns true for admin on any event" do
    event = events(:approved_upcoming)
    assert event.editable_by?(users(:admin))
  end

  test "editable_by? returns true for owner" do
    event = events(:approved_upcoming)
    assert event.editable_by?(users(:regular))
  end

  test "editable_by? returns false for non-owner non-admin" do
    event = events(:approved_upcoming)
    assert_not event.editable_by?(users(:organiser))
  end

  test "editable_by? returns false for nil user" do
    event = events(:approved_upcoming)
    assert_not event.editable_by?(nil)
  end

  # -- multi_day? --

  test "multi_day? false when no end_date" do
    event = events(:approved_upcoming)
    event.end_date = nil
    assert_not event.multi_day?
  end

  test "multi_day? false when end_date equals start_date" do
    event = events(:approved_upcoming)
    event.end_date = event.start_date
    assert_not event.multi_day?
  end

  test "multi_day? true when end_date differs from start_date" do
    event = events(:multi_day_event)
    assert event.multi_day?
  end

  # -- free? --

  test "free? true when cost is blank" do
    event = Event.new(cost: nil)
    assert event.free?
  end

  test "free? true when cost is empty string" do
    event = Event.new(cost: "")
    assert event.free?
  end

  test "free? true when cost contains free case insensitively" do
    assert Event.new(cost: "Free").free?
    assert Event.new(cost: "FREE").free?
    assert Event.new(cost: "free entry").free?
  end

  test "free? false when cost is a price" do
    assert_not Event.new(cost: "$50").free?
    assert_not Event.new(cost: "20 NZD").free?
  end

  # -- formatted_date --

  test "formatted_date for single day event" do
    event = Event.new(start_date: Date.new(2026, 3, 15), end_date: nil)
    assert_equal "Sunday, 15 March 2026", event.formatted_date
  end

  test "formatted_date for multi-day event" do
    event = Event.new(start_date: Date.new(2026, 3, 15), end_date: Date.new(2026, 3, 20))
    assert_equal "15 Mar - 20 Mar 2026", event.formatted_date
  end

  # -- region_display --

  test "region_display returns Asia Pacific for apac" do
    event = Event.new
    event.region = "apac"
    assert_equal "Asia Pacific", event.region_display
  end

  test "region_display titleizes other regions" do
    event = Event.new
    event.region = "wellington"
    assert_equal "Wellington", event.region_display
  end

  # -- primary_location --

  test "primary_location returns first event_location" do
    event = events(:approved_upcoming)
    assert_equal event.event_locations.first, event.primary_location
  end

  # -- multi_location? --

  test "multi_location? false with one location" do
    event = events(:approved_upcoming)
    assert_not event.multi_location?
  end

  test "multi_location? true with two or more locations" do
    event = events(:approved_upcoming)
    event.event_locations.build(region: :auckland, city: "Auckland CBD")
    assert event.multi_location?
  end

  # -- display_summary --

  test "display_summary returns short_summary when present" do
    event = events(:approved_upcoming)
    event.short_summary = "A quick summary"
    assert_equal "A quick summary", event.display_summary
  end

  test "display_summary returns truncated description when short_summary blank" do
    event = events(:approved_upcoming)
    event.short_summary = nil
    summary = event.display_summary
    assert summary.is_a?(String)
    assert summary.length <= 503  # 500 + "..." ellipsis
  end

  # ========== Associations ==========

  test "destroying event destroys associated locations" do
    event = events(:approved_upcoming)
    location_count = event.event_locations.count
    assert location_count > 0
    assert_difference("EventLocation.count", -location_count) do
      event.destroy
    end
  end
end
