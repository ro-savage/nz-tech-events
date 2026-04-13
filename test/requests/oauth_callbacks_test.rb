require "test_helper"

class OauthCallbacksRequestTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:regular)
    OmniAuth.config.test_mode = true
  end

  teardown do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    OmniAuth.config.test_mode = false
  end

  test "successful Google OAuth creates new user and starts session" do
    mock_google_auth(
      uid: "google-uid-new-user",
      email: "newuser@example.com",
      name: "New Google User",
      image: "https://example.com/avatar.png"
    )

    assert_difference("User.count", 1) do
      assert_difference("Session.count", 1) do
        get "/auth/google_oauth2/callback"
      end
    end

    new_user = User.find_by(email_address: "newuser@example.com")
    assert_not_nil new_user
    assert_equal "google-uid-new-user", new_user.google_uid
    assert_equal "New Google User", new_user.name
    assert_equal "https://example.com/avatar.png", new_user.avatar_url
    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
  end

  test "successful Google OAuth links to existing user by email" do
    mock_google_auth(
      uid: "google-uid-existing",
      email: @user.email_address,
      name: "Google Name",
      image: "https://example.com/existing-avatar.png"
    )

    assert_no_difference("User.count") do
      get "/auth/google_oauth2/callback"
    end

    @user.reload
    assert_equal "google-uid-existing", @user.google_uid
    assert_equal "https://example.com/existing-avatar.png", @user.avatar_url
    assert_redirected_to root_path
  end

  test "Google OAuth updates name when user name is blank" do
    @user.update_columns(name: nil)
    mock_google_auth(
      uid: "google-uid-blank-name",
      email: @user.email_address,
      name: "Name From Google",
      image: "https://example.com/avatar.png"
    )

    get "/auth/google_oauth2/callback"

    @user.reload
    assert_equal "Name From Google", @user.name
  end

  test "Google OAuth does not overwrite existing name" do
    original_name = @user.name
    mock_google_auth(
      uid: "google-uid-keep-name",
      email: @user.email_address,
      name: "Different Google Name",
      image: "https://example.com/avatar.png"
    )

    get "/auth/google_oauth2/callback"

    @user.reload
    assert_equal original_name, @user.name
  end

  test "Google OAuth does not update google_uid if already set" do
    @user.update_columns(google_uid: "original-uid")
    mock_google_auth(
      uid: "different-uid",
      email: @user.email_address,
      name: "Google Name",
      image: "https://example.com/new-avatar.png"
    )

    get "/auth/google_oauth2/callback"

    @user.reload
    assert_equal "original-uid", @user.google_uid
  end

  test "OAuth failure redirects to login with error message" do
    OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials

    get "/auth/failure?message=invalid_credentials&strategy=google_oauth2"

    assert_redirected_to new_session_path
    follow_redirect!
    assert_response :success
  end

  test "handles missing email in OAuth data by redirecting with error" do
    mock_google_auth(
      uid: "google-uid-no-email",
      email: nil,
      name: "No Email User",
      image: "https://example.com/avatar.png"
    )

    assert_no_difference("User.count") do
      get "/auth/google_oauth2/callback"
    end

    assert_redirected_to new_session_path
  end

  test "handles missing name gracefully for new user" do
    mock_google_auth(
      uid: "google-uid-no-name",
      email: "noname@example.com",
      name: nil,
      image: "https://example.com/avatar.png"
    )

    # Name is required for Google users (google_uid present), so this should fail
    assert_no_difference("User.count") do
      get "/auth/google_oauth2/callback"
    end

    assert_redirected_to new_session_path
  end

  private

  def mock_google_auth(uid:, email:, name:, image:)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: uid,
      info: OmniAuth::AuthHash::InfoHash.new(
        email: email,
        name: name,
        image: image
      )
    )
  end
end
