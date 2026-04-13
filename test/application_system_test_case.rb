require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 900]

  private

  def sign_in_as(user, password: "password123")
    visit new_session_path
    fill_in "Email", with: user.email_address
    fill_in "Password", with: password
    click_button "Sign In"
    assert_no_current_path new_session_path
  end
end
