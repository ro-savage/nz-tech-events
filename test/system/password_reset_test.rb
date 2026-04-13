require "application_system_test_case"

class PasswordResetTest < ApplicationSystemTestCase
  test "request password reset with email" do
    visit new_password_path

    assert_text "Forgot your password?"

    fill_in "email_address", with: users(:regular).email_address
    click_button "Email reset instructions"

    assert_text "Password reset instructions sent"
  end

  test "request password reset with unknown email shows same confirmation" do
    visit new_password_path

    fill_in "email_address", with: "unknown@example.com"
    click_button "Email reset instructions"

    assert_text "Password reset instructions sent"
  end
end
