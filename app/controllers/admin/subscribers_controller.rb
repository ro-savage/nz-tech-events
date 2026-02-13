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

  private

  def require_admin
    unless Current.user&.admin?
      redirect_to root_path, alert: "You are not authorized to access this page."
    end
  end
end
