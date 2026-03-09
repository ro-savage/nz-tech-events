require "test_helper"

class AdminMailerTest < ActionMailer::TestCase
  test "pending events reminder includes count and review link" do
    admin_user = users(:admin)
    mail = AdminMailer.pending_events_reminder(admin_user, 2)

    assert_equal [ admin_user.email_address ], mail.to
    assert_equal "2 pending events awaiting approval", mail.subject
    assert_match "2 pending events need approval", mail.body.encoded
    assert_match Rails.application.routes.url_helpers.admin_pending_events_url(host: "example.com"), mail.body.encoded
  end
end
