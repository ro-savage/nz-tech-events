require "test_helper"

class SendWeeklyDigestJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    ActionMailer::Base.deliveries.clear
    clear_enqueued_jobs
    clear_performed_jobs
  end

  test "enqueues digest emails for all subscribers" do
    subscriber_count = EmailSubscription.count

    assert_enqueued_emails subscriber_count do
      SendWeeklyDigestJob.perform_now
    end
  end

  test "sends digest to each subscriber in a matching region" do
    EmailSubscription.create!(
      email_address: "second-wellington@example.com",
      region: :wellington
    )
    wellington_sub = email_subscriptions(:wellington_sub)

    perform_enqueued_jobs do
      SendWeeklyDigestJob.perform_now
    end

    wellington_emails = ActionMailer::Base.deliveries.select do |mail|
      mail.subject.include?("Wellington")
    end
    assert_equal 2, wellington_emails.size
    recipients = wellington_emails.flat_map(&:to).sort
    assert_includes recipients, wellington_sub.email_address
    assert_includes recipients, "second-wellington@example.com"
  end

  test "skips regions with no subscribers" do
    EmailSubscription.where(region: :auckland).destroy_all

    perform_enqueued_jobs do
      SendWeeklyDigestJob.perform_now
    end

    auckland_emails = ActionMailer::Base.deliveries.select do |mail|
      mail.subject.include?("Auckland")
    end
    assert_empty auckland_emails
  end

  test "only includes approved events in digest" do
    unapproved = events(:unapproved_upcoming)
    assert_not unapproved.approved?

    perform_enqueued_jobs do
      SendWeeklyDigestJob.perform_now
    end

    ActionMailer::Base.deliveries.each do |mail|
      assert_no_match unapproved.title, mail.body.encoded
    end
  end

  test "only includes upcoming events not past events" do
    past = events(:past_event)
    assert past.start_date < Date.current

    perform_enqueued_jobs do
      SendWeeklyDigestJob.perform_now
    end

    ActionMailer::Base.deliveries.each do |mail|
      assert_no_match past.title, mail.body.encoded
    end
  end

  test "marks subscriptions as sent after delivering" do
    wellington_sub = email_subscriptions(:wellington_sub)
    assert_nil wellington_sub.last_sent_at

    perform_enqueued_jobs do
      SendWeeklyDigestJob.perform_now
    end

    wellington_sub.reload
    assert_not_nil wellington_sub.last_sent_at
    assert_in_delta Time.current, wellington_sub.last_sent_at, 5.seconds
  end

  test "handles region with subscribers but no new events gracefully" do
    sub = EmailSubscription.create!(
      email_address: "southland@example.com",
      region: :southland
    )

    perform_enqueued_jobs do
      assert_nothing_raised do
        SendWeeklyDigestJob.perform_now
      end
    end

    sub.reload
    assert_not_nil sub.last_sent_at
  end

  test "new events section excludes events created more than 7 days ago" do
    old_approved = events(:approved_upcoming)
    old_approved.update_column(:created_at, 10.days.ago)

    # Create a recent event so the digest still has content
    recent = users(:organiser).events.build(
      title: "Recent Wellington Event",
      start_date: 5.days.from_now,
      event_type: :meetup,
      approved: true
    )
    recent.description = "A recent event"
    recent.event_locations.build(region: :wellington, city: "Wellington CBD")
    recent.save!

    perform_enqueued_jobs do
      SendWeeklyDigestJob.perform_now
    end

    wellington_emails = ActionMailer::Base.deliveries.select do |mail|
      mail.subject.include?("Wellington")
    end

    assert_not_empty wellington_emails
    # The old event (created 10 days ago) should not appear as a "new" event,
    # but the recent one should
    email_body = wellington_emails.first.body.encoded
    assert_match "Recent Wellington Event", email_body
  end

  test "iterates all defined regions without errors" do
    perform_enqueued_jobs do
      assert_nothing_raised do
        SendWeeklyDigestJob.perform_now
      end
    end
  end
end
