require "test_helper"

class UsersRequestTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @regular = users(:regular)
    @organiser = users(:organiser)
  end

  # GET /users/:id (show - public)

  test "GET /users/:id returns 200 for anyone" do
    get user_path(@regular)
    assert_response :success
  end

  test "GET /users/:id returns 200 for logged-in user" do
    sign_in_as(@regular)
    get user_path(@organiser)
    assert_response :success
  end

  # GET /users (index - admin only)

  test "GET /users redirects unauthenticated user" do
    get users_path
    assert_redirected_to new_session_path
  end

  test "GET /users redirects non-admin" do
    sign_in_as(@regular)
    get users_path
    assert_redirected_to root_path
  end

  test "GET /users returns 200 for admin" do
    sign_in_as(@admin)
    get users_path
    assert_response :success
  end

  # POST /users/:id/toggle_approved_organiser

  test "POST toggle_approved_organiser toggles status for admin" do
    sign_in_as(@admin)
    assert_not @regular.approved_organiser?

    post toggle_approved_organiser_user_path(@regular)
    assert_redirected_to users_path

    @regular.reload
    assert @regular.approved_organiser?
  end

  test "POST toggle_approved_organiser redirects non-admin" do
    sign_in_as(@regular)
    post toggle_approved_organiser_user_path(@organiser)
    assert_redirected_to root_path
  end

  # DELETE /users/:id

  test "DELETE /users/:id admin can delete another user" do
    sign_in_as(@admin)
    assert_difference "User.count", -1 do
      delete user_path(@regular)
    end
    assert_redirected_to users_path
  end

  test "DELETE /users/:id admin cannot delete themselves" do
    sign_in_as(@admin)
    assert_no_difference "User.count" do
      delete user_path(@admin)
    end
    assert_redirected_to users_path
    follow_redirect!
    assert_select "body", /cannot delete your own account/
  end

  test "DELETE /users/:id non-admin redirected" do
    sign_in_as(@regular)
    assert_no_difference "User.count" do
      delete user_path(@organiser)
    end
    assert_redirected_to root_path
  end
end
