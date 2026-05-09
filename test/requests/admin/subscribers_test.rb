require "test_helper"

class Admin::SubscribersRequestTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @regular = users(:regular)
  end

  # GET /admin/subscribers - authentication and authorization

  test "GET /admin/subscribers redirects unauthenticated user" do
    get admin_subscribers_path
    assert_redirected_to new_session_path
  end

  test "GET /admin/subscribers redirects non-admin user" do
    sign_in_as(@regular)
    get admin_subscribers_path
    assert_redirected_to root_path
  end

  test "GET /admin/subscribers returns 200 for admin" do
    sign_in_as(@admin)
    get admin_subscribers_path
    assert_response :success
  end

  # GET /admin/subscribers - content

  test "GET /admin/subscribers displays subscriber email addresses" do
    sign_in_as(@admin)
    get admin_subscribers_path

    assert_response :success
    assert_select "td", text: email_subscriptions(:wellington_sub).email_address
    assert_select "td", text: email_subscriptions(:auckland_sub).email_address
  end

  test "GET /admin/subscribers displays subscription regions" do
    sign_in_as(@admin)
    get admin_subscribers_path

    assert_response :success
    wellington_region = email_subscriptions(:wellington_sub).region_display
    auckland_region = email_subscriptions(:auckland_sub).region_display
    assert_select "td", text: wellington_region
    assert_select "td", text: auckland_region
  end

  test "GET /admin/subscribers returns 200 with no subscribers" do
    EmailSubscription.delete_all

    sign_in_as(@admin)
    get admin_subscribers_path

    assert_response :success
    assert_select "table tbody tr", count: 0
  end
end
