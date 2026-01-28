class WeeklyDigestMailer < ApplicationMailer
  def digest(subscription, new_events, upcoming_events)
    @subscription = subscription
    @new_events = new_events
    @upcoming_events = upcoming_events
    @region_display = subscription.region_display
    @week_of = Date.current.strftime("%B %d, %Y")
    @unsubscribe_url = unsubscribe_url(token: subscription.unsubscribe_token)

    mail(
      to: subscription.email_address,
      subject: "#{@region_display} Tech Events - Week of #{@week_of}"
    )
  end
end
