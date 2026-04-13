require "test_helper"

class PasswordsRequestTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:regular)
  end

  test "GET /passwords/new renders the forgot password form" do
    get new_password_path
    assert_response :success
    assert_select "h1", "Forgot your password?"
    assert_select "input[type=email][name=email_address]"
    assert_select "button[type=submit]", "Email reset instructions"
  end

  test "POST /passwords with valid email sends reset email and redirects" do
    assert_enqueued_email_with PasswordsMailer, :reset, args: [@user] do
      post passwords_path, params: { email_address: @user.email_address }
    end
    assert_redirected_to new_session_path
    follow_redirect!
    assert_select "body", /Password reset instructions sent/
  end

  test "POST /passwords with unknown email still shows success message" do
    assert_no_enqueued_emails do
      post passwords_path, params: { email_address: "nonexistent@example.com" }
    end
    assert_redirected_to new_session_path
    follow_redirect!
    assert_select "body", /Password reset instructions sent/
  end

  test "POST /passwords with blank email shows success and does not send email" do
    assert_no_enqueued_emails do
      post passwords_path, params: { email_address: "" }
    end
    assert_redirected_to new_session_path
    follow_redirect!
    assert_select "body", /Password reset instructions sent/
  end

  test "GET /passwords/:token/edit with valid token renders reset form" do
    token = @user.password_reset_token
    get edit_password_path(token)
    assert_response :success
    assert_select "h1", "Update your password"
    assert_select "input[type=password][name=password]"
    assert_select "input[type=password][name=password_confirmation]"
  end

  test "GET /passwords/:token/edit with invalid token redirects with error" do
    get edit_password_path("invalid-token")
    assert_redirected_to new_password_path
    follow_redirect!
    assert_select "body", /Password reset link is invalid or has expired/
  end

  test "PATCH /passwords/:token with valid token and matching passwords resets password" do
    token = @user.password_reset_token
    patch password_path(token), params: { password: "newpassword123", password_confirmation: "newpassword123" }
    assert_redirected_to new_session_path
    follow_redirect!
    assert_select "body", /Password has been reset/

    # Verify the new password works
    post session_path, params: { email_address: @user.email_address, password: "newpassword123" }
    assert_response :redirect
  end

  test "PATCH /passwords/:token with mismatched passwords shows errors" do
    token = @user.password_reset_token
    patch password_path(token), params: { password: "newpassword123", password_confirmation: "differentpassword" }
    assert_redirected_to edit_password_path(token)
    follow_redirect!
    assert_select "body", /Passwords did not match/
  end

  test "password reset destroys all existing sessions for the user" do
    # Create sessions by signing in
    sign_in_as(@user)
    initial_session_count = @user.sessions.count
    assert initial_session_count > 0, "User should have at least one session"

    token = @user.password_reset_token
    patch password_path(token), params: { password: "newpassword123", password_confirmation: "newpassword123" }
    assert_redirected_to new_session_path

    assert_equal 0, @user.sessions.reload.count, "All sessions should be destroyed after password reset"
  end
end
