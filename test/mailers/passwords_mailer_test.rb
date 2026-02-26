require "test_helper"

class PasswordsMailerTest < ActionMailer::TestCase
  test "reset email is sent to the user" do
    user = users(:regular)
    mail = PasswordsMailer.reset(user)

    assert_equal [ user.email_address ], mail.to
  end

  test "reset email subject mentions password reset" do
    user = users(:regular)
    mail = PasswordsMailer.reset(user)

    assert_equal "Reset your password", mail.subject
  end

  test "reset email body includes password reset link" do
    user = users(:regular)
    mail = PasswordsMailer.reset(user)

    assert_match "password reset page", mail.body.encoded
  end
end
