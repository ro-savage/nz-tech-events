require "test_helper"

class EventMailerTest < ActionMailer::TestCase
  test "approved email is sent to event owner" do
    event = events(:approved_upcoming)
    mail = EventMailer.approved(event)

    assert_equal [ event.user.email_address ], mail.to
    assert_equal "Your NZ Tech Event has been approved", mail.subject
    assert_equal [ "rowan.savage@gmail.com" ], mail.reply_to
    assert_match event.title, mail.body.encoded
    assert_match "approved", mail.body.encoded
  end

  test "approved email includes event owner greeting" do
    event = events(:approved_upcoming)
    mail = EventMailer.approved(event)

    assert_match event.user.name || event.user.email_address, mail.body.encoded
  end
end
