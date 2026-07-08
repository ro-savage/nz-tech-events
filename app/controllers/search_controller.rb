class SearchController < ApplicationController
  def index
    if params[:q].present?
      @query = params[:q].strip
      @events = Event.approved.upcoming.search(@query)
                     .includes(:event_locations, :user)
                     .order(start_date: :asc)
    else
      @events = Event.none
    end
  end
end
