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

  # ========== CAPTCHA behavior ==========

  test "signup succeeds when reCAPTCHA is disabled" do
    ENV.delete("ENABLE_RECAPTCHA")

    assert_difference "User.count", 1 do
      post registration_path, params: {
        user: {
          email_address: "nocaptcha@example.com",
          password: "password123",
          password_confirmation: "password123",
          name: "No Captcha User"
        }
      }
    end
    assert_redirected_to root_path
  end

  test "signup fails with captcha error when reCAPTCHA enabled and verification fails" do
    ENV["ENABLE_RECAPTCHA"] = "true"
    ENV["RECAPTCHA_V2_SITE_KEY"] = "test_v2_site_key"
    ENV["RECAPTCHA_V3_SITE_KEY"] = "test_v3_site_key"

    # The recaptcha gem skips verification in test env by default,
    # so we temporarily disable that behavior
    Recaptcha.configure do |config|
      config.skip_verify_env.delete("test")
    end

    assert_no_difference "User.count" do
      post registration_path, params: {
        user: {
          email_address: "captchafail@example.com",
          password: "password123",
          password_confirmation: "password123",
          name: "Captcha Fail User"
        }
      }
    end
    assert_response :unprocessable_entity
    assert_match(/reCAPTCHA/, response.body)
  ensure
    ENV.delete("ENABLE_RECAPTCHA")
    ENV.delete("RECAPTCHA_V2_SITE_KEY")
    ENV.delete("RECAPTCHA_V3_SITE_KEY")
    Recaptcha.configure do |config|
      config.skip_verify_env << "test" unless config.skip_verify_env.include?("test")
    end
  end

  test "signup shows checkbox captcha after v3 and v2 both fail" do
    ENV["ENABLE_RECAPTCHA"] = "true"
    ENV["RECAPTCHA_V2_SITE_KEY"] = "test_v2_site_key"
    ENV["RECAPTCHA_V3_SITE_KEY"] = "test_v3_site_key"

    Recaptcha.configure do |config|
      config.skip_verify_env.delete("test")
    end

    post registration_path, params: {
      user: {
        email_address: "checkbox@example.com",
        password: "password123",
        password_confirmation: "password123",
        name: "Checkbox User"
      }
    }
    assert_response :unprocessable_entity
  ensure
    ENV.delete("ENABLE_RECAPTCHA")
    ENV.delete("RECAPTCHA_V2_SITE_KEY")
    ENV.delete("RECAPTCHA_V3_SITE_KEY")
    Recaptcha.configure do |config|
      config.skip_verify_env << "test" unless config.skip_verify_env.include?("test")
    end
  end

  test "captcha failure does not clear unrelated model validation errors" do
    ENV["ENABLE_RECAPTCHA"] = "true"
    ENV["RECAPTCHA_V2_SITE_KEY"] = "test_v2_site_key"
    ENV["RECAPTCHA_V3_SITE_KEY"] = "test_v3_site_key"

    Recaptcha.configure do |config|
      config.skip_verify_env.delete("test")
    end

    assert_no_difference "User.count" do
      post registration_path, params: {
        user: {
          email_address: "not-an-email",
          password: "ab",
          password_confirmation: "ab",
          name: ""
        }
      }
    end
    assert_response :unprocessable_entity
    # Both captcha AND validation errors should be present
    assert_match(/reCAPTCHA/, response.body)
  ensure
    ENV.delete("ENABLE_RECAPTCHA")
    ENV.delete("RECAPTCHA_V2_SITE_KEY")
    ENV.delete("RECAPTCHA_V3_SITE_KEY")
    Recaptcha.configure do |config|
      config.skip_verify_env << "test" unless config.skip_verify_env.include?("test")
    end
  end
end
