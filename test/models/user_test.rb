require "test_helper"

class UserTest < ActiveSupport::TestCase
  # -- Validations --

  test "valid user with email and password" do
    user = User.new(email_address: "new@example.com", password: "password123")
    assert user.valid?
  end

  test "email_address is required" do
    user = User.new(password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "can't be blank"
  end

  test "email_address must be unique" do
    users(:regular) # ensure fixture loaded
    user = User.new(email_address: "regular@example.com", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "has already been taken"
  end

  test "email_address must have valid format" do
    user = User.new(email_address: "notanemail", password: "password123")
    assert_not user.valid?
    assert user.errors[:email_address].any?
  end

  test "password must be at least 8 characters" do
    user = User.new(email_address: "short@example.com", password: "short")
    assert_not user.valid?
    assert user.errors[:password].any?
  end

  test "password of exactly 8 characters is valid" do
    user = User.new(email_address: "exact@example.com", password: "12345678")
    assert user.valid?
  end

  test "name required when google_uid present" do
    user = User.new(email_address: "oauth@example.com", password: "password123", google_uid: "123")
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "name not required when google_uid absent" do
    user = User.new(email_address: "noname@example.com", password: "password123")
    assert user.valid?
  end

  # -- Email normalization --

  test "email is stripped and downcased" do
    user = User.new(email_address: "  Test@Example.COM  ", password: "password123")
    assert_equal "test@example.com", user.email_address
  end

  # -- display_name --

  test "display_name returns name when present" do
    user = User.new(name: "Alice", email_address: "alice@example.com")
    assert_equal "Alice", user.display_name
  end

  test "display_name returns email prefix when name blank" do
    user = User.new(email_address: "bob@example.com")
    assert_equal "bob", user.display_name
  end

  test "display_name returns email prefix when name is empty string" do
    user = User.new(name: "", email_address: "charlie@example.com")
    assert_equal "charlie", user.display_name
  end

  # -- google_user? --

  test "google_user? true when google_uid present" do
    user = User.new(google_uid: "abc123")
    assert user.google_user?
  end

  test "google_user? false when google_uid nil" do
    user = User.new(google_uid: nil)
    assert_not user.google_user?
  end

  # -- admin? --

  test "admin? true when admin is true" do
    assert users(:admin).admin?
  end

  test "admin? false when admin is false" do
    assert_not users(:regular).admin?
  end

  # -- approved_organiser? --

  test "approved_organiser? true when column is true" do
    assert users(:organiser).approved_organiser?
  end

  test "approved_organiser? false when column is false" do
    assert_not users(:regular).approved_organiser?
  end

  # -- can_create_event? --

  test "admin can always create events" do
    assert users(:admin).can_create_event?
  end

  test "approved organiser can always create events" do
    assert users(:organiser).can_create_event?
  end

  test "regular user can create events when under limit" do
    assert users(:regular).can_create_event?
  end

  test "regular user cannot create events when at rate limit" do
    user = users(:regular)
    # Create 10 events in the last 24 hours
    10.times do |i|
      event = user.events.build(
        title: "Rate limit test #{i}",
        start_date: 1.week.from_now,
        event_type: :meetup
      )
      event.description = "Test description"
      event.event_locations.build(region: :wellington, city: "Wellington CBD")
      event.save!(validate: false)
      event.update_column(:created_at, 1.hour.ago)
    end
    assert_not user.can_create_event?
  end

  # -- events_created_in_last_24_hours --

  test "events_created_in_last_24_hours counts only recent events" do
    user = users(:regular)
    # Fixtures may have events but they were created at fixture load time
    initial_count = user.events_created_in_last_24_hours
    event = user.events.build(
      title: "Recent event",
      start_date: 1.week.from_now,
      event_type: :meetup
    )
    event.description = "Test"
    event.event_locations.build(region: :wellington, city: "Wellington CBD")
    event.save!(validate: false)
    assert_equal initial_count + 1, user.events_created_in_last_24_hours
  end

  # -- Associations --

  test "destroying user destroys associated events" do
    user = users(:regular)
    event_count = user.events.count
    assert event_count > 0, "Fixture user should have events"
    assert_difference("Event.count", -event_count) do
      user.destroy
    end
  end

  test "destroying user destroys associated sessions" do
    user = users(:regular)
    user.sessions.create!
    assert_difference("Session.count", -user.sessions.count) do
      user.destroy
    end
  end
end
