require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  test "sign up with email and password" do
    visit new_registration_path

    assert_text "Create Account"

    fill_in "user_name", with: "New User"
    fill_in "user_email_address", with: "newuser@example.com"
    fill_in "user_password", with: "password123"
    fill_in "user_password_confirmation", with: "password123"
    click_button "Create Account"

    assert_text "Account created successfully"
  end

  test "log out redirects to login page" do
    sign_in_as(users(:regular))
    assert_text "Wellington Ruby Meetup"

    find(".hamburger").click
    click_on "Sign Out"

    assert_current_path new_session_path
  end

  test "log in with valid credentials" do
    visit new_session_path

    fill_in "Email", with: users(:regular).email_address
    fill_in "Password", with: "password123"
    click_button "Sign In"

    assert_text "Wellington Ruby Meetup"
  end

  test "log in with invalid credentials shows error" do
    visit new_session_path

    fill_in "Email", with: users(:regular).email_address
    fill_in "Password", with: "wrongpassword"
    click_button "Sign In"

    assert_text "Try another email address or password"
  end

  test "login page has expected form elements" do
    visit new_session_path

    assert_text "Sign In"
    assert_selector "input[type='email']"
    assert_selector "input[type='password']"
    assert_selector "button[type='submit']"
    assert_text "Don't have an account?"
  end
end
