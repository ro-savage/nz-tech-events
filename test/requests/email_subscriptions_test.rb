require "test_helper"

class EmailSubscriptionsRequestTest < ActionDispatch::IntegrationTest
  setup do
    @wellington_sub = email_subscriptions(:wellington_sub)
    @auckland_sub = email_subscriptions(:auckland_sub)
  end

  # GET /subscribe

  test "GET /subscribe returns 200" do
    get new_email_subscription_path
    assert_response :success
  end

  # POST /subscribe

  test "POST /subscribe with valid params creates subscription and redirects" do
    assert_difference "EmailSubscription.count", 1 do
      post email_subscriptions_path, params: {
        email_subscription: {
          email_address: "newsubscriber@example.com",
          region: "canterbury"
        }
      }
    end
    assert_redirected_to root_path
  end

  test "POST /subscribe with invalid email renders errors" do
    assert_no_difference "EmailSubscription.count" do
      post email_subscriptions_path, params: {
        email_subscription: {
          email_address: "not-valid",
          region: "wellington"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "POST /subscribe with duplicate email and region renders errors" do
    assert_no_difference "EmailSubscription.count" do
      post email_subscriptions_path, params: {
        email_subscription: {
          email_address: @wellington_sub.email_address,
          region: "wellington"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  # GET /unsubscribe/:token

  test "GET /unsubscribe with valid token destroys subscription" do
    assert_difference "EmailSubscription.count", -1 do
      get unsubscribe_path(token: @wellington_sub.unsubscribe_token)
    end
    assert_response :success
  end

  test "GET /unsubscribe with invalid token redirects with alert" do
    assert_no_difference "EmailSubscription.count" do
      get unsubscribe_path(token: "invalid_token_xyz")
    end
    assert_redirected_to root_path
  end
end
