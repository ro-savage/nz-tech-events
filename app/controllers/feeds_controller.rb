class FeedsController < ApplicationController
  MAX_FEED_EVENTS = 50

  def events
    @events = Event.approved.upcoming
                   .includes(:event_locations, :user)
                   .limit(MAX_FEED_EVENTS)
                   .to_a

    @feed_updated_at = @events.map(&:updated_at).max || Time.current

    respond_to do |format|
      format.rss { render layout: false }
      format.atom { render layout: false }
    end
  end
end
