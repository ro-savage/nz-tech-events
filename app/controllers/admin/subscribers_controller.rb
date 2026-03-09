class Admin::SubscribersController < ApplicationController
  before_action :require_login
  before_action :require_admin

  def index
    subscriptions = EmailSubscription.order(:email_address)
    grouped = subscriptions.group_by(&:email_address)

    @subscribers = grouped.map do |email, subs|
      { email: email, regions: subs.map(&:region_display).sort }
    end

    @subscriber_count = @subscribers.length
  end
end
