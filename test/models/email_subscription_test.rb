require "test_helper"

class EmailSubscriptionTest < ActiveSupport::TestCase
  # -- Validations --

  test "valid subscription with email and region" do
    sub = EmailSubscription.new(email_address: "new@example.com", region: :canterbury)
    assert sub.valid?
  end

  test "email_address is required" do
    sub = EmailSubscription.new(region: :wellington)
    assert_not sub.valid?
    assert sub.errors[:email_address].any?
  end

  test "email_address must be valid format" do
    sub = EmailSubscription.new(email_address: "notanemail", region: :wellington)
    assert_not sub.valid?
    assert sub.errors[:email_address].any?
  end

  test "region is required" do
    sub = EmailSubscription.new(email_address: "test@example.com")
    assert_not sub.valid?
    assert sub.errors[:region].any?
  end

  test "email uniqueness is scoped to region" do
    existing = email_subscriptions(:wellington_sub)
    # Same email, same region = invalid
    dup = EmailSubscription.new(email_address: existing.email_address, region: existing.region)
    assert_not dup.valid?
    assert dup.errors[:email_address].any? { |e| e.include?("already subscribed") }
  end

  test "same email different region is valid" do
    existing = email_subscriptions(:wellington_sub)
    sub = EmailSubscription.new(email_address: existing.email_address, region: :auckland)
    assert sub.valid?
  end

  # -- Callback: generate_unsubscribe_token --

  test "unsubscribe_token is generated before create" do
    sub = EmailSubscription.new(email_address: "tokentest@example.com", region: :otago)
    assert_nil sub.unsubscribe_token
    sub.save!
    assert_not_nil sub.unsubscribe_token
    assert sub.unsubscribe_token.length > 10
  end

  test "unsubscribe_token is unique per subscription" do
    sub1 = EmailSubscription.create!(email_address: "unique1@example.com", region: :otago)
    sub2 = EmailSubscription.create!(email_address: "unique2@example.com", region: :otago)
    assert_not_equal sub1.unsubscribe_token, sub2.unsubscribe_token
  end

  # -- region_display --

  test "region_display returns Asia Pacific for apac" do
    sub = EmailSubscription.new(region: :apac)
    assert_equal "Asia Pacific", sub.region_display
  end

  test "region_display titleizes other regions" do
    sub = EmailSubscription.new(region: :wellington)
    assert_equal "Wellington", sub.region_display
  end

  test "region_display titleizes underscore regions" do
    sub = EmailSubscription.new(region: :manawatu_whanganui)
    assert_equal "Manawatu Whanganui", sub.region_display
  end

  # -- mark_sent! --

  test "mark_sent! updates last_sent_at" do
    sub = email_subscriptions(:wellington_sub)
    assert_nil sub.last_sent_at
    freeze_time do
      sub.mark_sent!
      assert_equal Time.current, sub.reload.last_sent_at
    end
  end

  # -- events_cutoff_date --

  test "events_cutoff_date returns 7 days ago" do
    sub = email_subscriptions(:wellington_sub)
    freeze_time do
      assert_equal 7.days.ago.to_date, sub.events_cutoff_date
    end
  end

  # -- Fixture sanity --

  test "wellington_sub fixture has correct attributes" do
    sub = email_subscriptions(:wellington_sub)
    assert_equal "subscriber@example.com", sub.email_address
    assert sub.region_wellington?
    assert_not_nil sub.unsubscribe_token
  end

  test "auckland_sub fixture has correct attributes" do
    sub = email_subscriptions(:auckland_sub)
    assert_equal "auckland_subscriber@example.com", sub.email_address
    assert sub.region_auckland?
  end
end
