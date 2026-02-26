require "test_helper"

class RegistrationsRequestTest < ActionDispatch::IntegrationTest
  test "GET /signup returns 200" do
    get new_registration_path
    assert_response :success
  end

  test "POST /signup with valid params creates user and redirects" do
    assert_difference "User.count", 1 do
      post registration_path, params: {
        user: {
          email_address: "newuser@example.com",
          password: "password123",
          password_confirmation: "password123",
          name: "New User"
        }
      }
    end
    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
  end

  test "POST /signup with invalid email renders errors" do
    assert_no_difference "User.count" do
      post registration_path, params: {
        user: {
          email_address: "not-an-email",
          password: "password123",
          password_confirmation: "password123",
          name: "Bad Email User"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "POST /signup with short password renders errors" do
    assert_no_difference "User.count" do
      post registration_path, params: {
        user: {
          email_address: "short@example.com",
          password: "ab",
          password_confirmation: "ab",
          name: "Short Password User"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "POST /signup with duplicate email renders errors" do
    existing_user = users(:regular)
    assert_no_difference "User.count" do
      post registration_path, params: {
        user: {
          email_address: existing_user.email_address,
          password: "password123",
          password_confirmation: "password123",
          name: "Duplicate User"
        }
      }
    end
    assert_response :unprocessable_entity
  end
end
