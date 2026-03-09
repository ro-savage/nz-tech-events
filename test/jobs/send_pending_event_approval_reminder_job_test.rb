require "test_helper"

class SendPendingEventApprovalReminderJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    ActionMailer::Base.deliveries.clear
    clear_enqueued_jobs
    clear_performed_jobs
  end

  test "sends one reminder email to each admin when pending events exist" do
    User.create!(
      email_address: "second-admin@example.com",
      password: "password123",
      name: "Second Admin",
      admin: true
    )
    pending_events_count = Event.pending_approval.count

    perform_enqueued_jobs do
      assert_emails User.admins.count do
        SendPendingEventApprovalReminderJob.perform_now
      end
    end

    assert_equal User.admins.order(:email_address).pluck(:email_address).sort,
                 ActionMailer::Base.deliveries.flat_map(&:to).sort
    assert_equal [ "#{pending_events_count} pending #{'event'.pluralize(pending_events_count)} awaiting approval" ],
                 ActionMailer::Base.deliveries.map(&:subject).uniq
  end

  test "does not send reminder emails when there are no pending events" do
    Event.pending_approval.update_all(approved: true)

    perform_enqueued_jobs do
      assert_no_emails do
        SendPendingEventApprovalReminderJob.perform_now
      end
    end
  end
end
