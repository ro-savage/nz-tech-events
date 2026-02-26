require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "approved_organiser email is sent to the user" do
    user = users(:regular)
    mail = UserMailer.approved_organiser(user)

    assert_equal [ user.email_address ], mail.to
  end

  test "approved_organiser email subject mentions upgrade" do
    user = users(:regular)
    mail = UserMailer.approved_organiser(user)

    assert_equal "Your NZ Tech Events account has been upgraded", mail.subject
  end

  test "approved_organiser email body includes user greeting" do
    user = users(:regular)
    mail = UserMailer.approved_organiser(user)

    assert_match user.name || user.email_address, mail.body.encoded
  end

  test "approved_organiser email body mentions auto approval" do
    user = users(:regular)
    mail = UserMailer.approved_organiser(user)

    assert_match "automatically approved", mail.body.encoded
  end

  test "approved_organiser email has correct reply-to" do
    user = users(:regular)
    mail = UserMailer.approved_organiser(user)

    assert_equal [ "rowan.savage@gmail.com" ], mail.reply_to
  end
end
