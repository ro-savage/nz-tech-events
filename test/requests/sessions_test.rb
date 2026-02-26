require "test_helper"

class SessionsRequestTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:regular)
  end

  test "GET /login returns 200" do
    get new_session_path
    assert_response :success
  end

  test "POST /login with valid credentials creates session and redirects" do
    post session_path, params: { email_address: @user.email_address, password: "password123" }
    assert_response :redirect
    follow_redirect!
    assert_response :success
  end

  test "POST /login with invalid credentials redirects back with alert" do
    post session_path, params: { email_address: @user.email_address, password: "wrongpassword" }
    assert_redirected_to new_session_path
    follow_redirect!
    assert_select "body", /Try another email address or password/
  end

  test "DELETE /logout destroys session and redirects to login" do
    sign_in_as(@user)
    delete logout_path
    assert_redirected_to new_session_path
  end
end
