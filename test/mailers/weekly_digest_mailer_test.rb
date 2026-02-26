require "test_helper"

class WeeklyDigestMailerTest < ActionMailer::TestCase
  setup do
    @subscription = email_subscriptions(:wellington_sub)
    @new_events = [ events(:approved_upcoming) ]
    @upcoming_events = [ events(:approved_upcoming), events(:free_event) ]
    @new_events_nz = [ events(:paid_event) ]
  end

  test "digest email is sent to subscriber" do
    mail = WeeklyDigestMailer.digest(@subscription, @new_events, @upcoming_events, @new_events_nz)

    assert_equal [ @subscription.email_address ], mail.to
  end

  test "digest subject includes region name and week" do
    mail = WeeklyDigestMailer.digest(@subscription, @new_events, @upcoming_events, @new_events_nz)

    assert_includes mail.subject, @subscription.region_display
    assert_includes mail.subject, "Week of"
  end

  test "digest body includes new event titles" do
    mail = WeeklyDigestMailer.digest(@subscription, @new_events, @upcoming_events, @new_events_nz)

    @new_events.each do |event|
      assert_match event.title, mail.body.encoded
    end
  end

  test "digest body includes upcoming event titles" do
    mail = WeeklyDigestMailer.digest(@subscription, @new_events, @upcoming_events, @new_events_nz)

    @upcoming_events.each do |event|
      assert_match event.title, mail.body.encoded
    end
  end

  test "digest body includes nationwide event titles" do
    mail = WeeklyDigestMailer.digest(@subscription, @new_events, @upcoming_events, @new_events_nz)

    @new_events_nz.each do |event|
      assert_match event.title, mail.body.encoded
    end
  end

  test "digest body includes unsubscribe link with token" do
    mail = WeeklyDigestMailer.digest(@subscription, @new_events, @upcoming_events, @new_events_nz)

    assert_match @subscription.unsubscribe_token, mail.body.encoded
    assert_match "Unsubscribe", mail.body.encoded
  end

  test "digest with empty event lists renders without errors" do
    mail = WeeklyDigestMailer.digest(@subscription, [], [], [])

    assert_equal [ @subscription.email_address ], mail.to
    assert_match "No new events", mail.body.encoded
  end
end
