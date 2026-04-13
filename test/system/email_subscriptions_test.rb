require "application_system_test_case"

class EmailSubscriptionsTest < ApplicationSystemTestCase
  test "subscribe to weekly updates with email and region" do
    visit new_email_subscription_path

    assert_text "Subscribe to Weekly Email Updates"

    fill_in "Email Address", with: "newtester@example.com"
    select "Wellington", from: "Region"
    click_button "Subscribe"

    assert_text "subscribed"
  end

  test "unsubscribe with valid token" do
    subscription = email_subscriptions(:wellington_sub)

    visit unsubscribe_path(token: subscription.unsubscribe_token)

    assert_text "You've Been Unsubscribed"
    assert_text "Wellington"
  end
end
