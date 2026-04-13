class FeedsController < ApplicationController
  MAX_FEED_EVENTS = 50

  def events
    @events = Event.approved.upcoming
                   .includes(:event_locations, :user)
                   .limit(MAX_FEED_EVENTS)

    respond_to do |format|
      format.rss { render layout: false }
      format.atom { render layout: false }
    end
  end
end
