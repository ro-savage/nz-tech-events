require "test_helper"

class ApiTokensControllerTest < ActionDispatch::IntegrationTest
  # ============================================================
  # Authentication
  # ============================================================

  test "index redirects when not logged in" do
    get api_tokens_path
    assert_redirected_to new_session_path
  end

  test "index redirects for regular user" do
    sign_in_as(users(:regular))
    get api_tokens_path
    assert_redirected_to root_path
  end

  # ============================================================
  # Index
  # ============================================================

  test "organiser can view tokens page" do
    sign_in_as(users(:organiser))
    get api_tokens_path
    assert_response :success
  end

  test "admin can view tokens page" do
    sign_in_as(users(:admin))
    get api_tokens_path
    assert_response :success
  end

  test "index shows only current user's tokens" do
    sign_in_as(users(:organiser))
    get api_tokens_path
    assert_response :success
    assert_select "td", text: "Test Token"
  end

  # ============================================================
  # Create
  # ============================================================

  test "create redirects when not logged in" do
    post api_tokens_path, params: { api_token: { name: "Test" } }
    assert_redirected_to new_session_path
  end

  test "regular user cannot create token" do
    sign_in_as(users(:regular))
    assert_no_difference("ApiToken.count") do
      post api_tokens_path, params: { api_token: { name: "Sneaky" } }
    end
    assert_redirected_to root_path
  end

  test "organiser can create token" do
    sign_in_as(users(:organiser))
    assert_difference("ApiToken.count", 1) do
      post api_tokens_path, params: { api_token: { name: "My New Token" } }
    end
    assert_redirected_to api_tokens_path
    assert flash[:token].present?
    assert flash[:token].start_with?("techevents_")
  end

  test "create with blank name shows error" do
    sign_in_as(users(:organiser))
    assert_no_difference("ApiToken.count") do
      post api_tokens_path, params: { api_token: { name: "" } }
    end
    assert_response :unprocessable_entity
  end

  # ============================================================
  # Destroy
  # ============================================================

  test "organiser can revoke own token" do
    sign_in_as(users(:organiser))
    token = api_tokens(:organiser_token)
    assert_difference("ApiToken.count", -1) do
      delete api_token_path(token)
    end
    assert_redirected_to api_tokens_path
  end

  test "organiser cannot revoke another user's token" do
    sign_in_as(users(:organiser))
    token = api_tokens(:admin_token)
    assert_no_difference("ApiToken.count") do
      delete api_token_path(token)
    end
    assert_redirected_to api_tokens_path
  end
end
