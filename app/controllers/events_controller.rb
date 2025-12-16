class EventsController < ApplicationController
  include EventsHelper

  before_action :require_login, only: [ :new, :create, :edit, :update, :destroy, :my_events ]
  before_action :set_event, only: [ :show, :edit, :update, :destroy, :ical ]
  before_action :authorize_owner!, only: [ :edit, :update, :destroy ]

  def index
    @events = Event.upcoming.approved.includes(:user, :event_locations)
    @initial_region = params[:region] if params[:region].present?
    @initial_city = params[:city] if params[:city].present?
  end

  def past
    @events = Event.past.includes(:user, :event_locations).limit(100)
  end

  def my_events
    @events = Current.user.events.includes(:event_locations).order(start_date: :desc)
  end

  def show
  end

  def new
    @event = Current.user.events.build
    @event.start_date = Date.tomorrow
    @event.event_locations.build
  end

  def create
    @event = Current.user.events.build(event_params)

    if @event.save
      if @event.approved?
        redirect_to @event, notice: "Event created successfully!"
      else
        redirect_to @event, notice: "Event created! It will appear on the events list once approved by an admin."
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @event.event_locations.build if @event.event_locations.empty?
  end

  def update
    if @event.update(event_params)
      redirect_to @event, notice: "Event updated successfully!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @event.destroy
    redirect_to root_path, notice: "Event deleted successfully!"
  end

  def ical
    filename = "#{@event.title.parameterize}-#{@event.start_date}.ics"

    send_data ical_content(@event),
              type: "text/calendar; charset=UTF-8",
              disposition: "attachment",
              filename: filename
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def authorize_owner!
    unless logged_in? && (Current.user.admin? || @event.owned_by?(Current.user))
      redirect_to root_path, alert: "You are not authorized to modify this event."
    end
  end

  def event_params
    params.require(:event).permit(
      :title, :description, :short_summary, :start_date, :end_date,
      :start_time, :end_time, :cost, :event_type,
      :registration_url, :region, :city, :address,
      event_locations_attributes: [ :id, :region, :city, :position, :_destroy ]
    )
  end
end
