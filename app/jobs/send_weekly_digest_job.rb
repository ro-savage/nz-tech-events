class SendWeeklyDigestJob < ApplicationJob
  queue_as :default

  def perform
    # Group subscriptions by region
    EmailSubscription.regions.keys.each do |region|
      subscriptions = EmailSubscription.where(region: EmailSubscription.regions[region])
      next if subscriptions.empty?

      # Fetch new events (created in last 7 days, approved, upcoming) for this region
      new_events = Event.upcoming
                        .approved
                        .by_region(region)
                        .where("events.created_at >= ?", 7.days.ago)
                        .order(:start_date)
                        .distinct

      # Fetch all upcoming approved events for this region
      upcoming_events = Event.upcoming
                             .approved
                             .by_region(region)
                             .order(:start_date)
                             .distinct

      # Convert to arrays for serialization (deliver_later can't serialize ActiveRecord::Relation)
      new_events_array = new_events.to_a
      upcoming_events_array = upcoming_events.to_a

      # Send email to each subscriber
      subscriptions.find_each do |subscription|
        WeeklyDigestMailer.digest(subscription, new_events_array, upcoming_events_array).deliver_later
        subscription.mark_sent!
      end
    end
  end
end
