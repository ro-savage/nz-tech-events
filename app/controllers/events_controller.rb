class EventsController < ApplicationController
  include EventsHelper

  before_action :require_login, only: [ :new, :create, :edit, :update, :destroy, :my_events ]
  before_action :set_event, only: [ :show, :edit, :update, :destroy, :ical ]
  before_action :authorize_owner!, only: [ :edit, :update, :destroy ]

  def index
    events = Event.upcoming.approved.includes(:user, :event_locations)
    @events_by_month = events.group_by { |e| e.start_date.beginning_of_month }
    @initial_region = params[:region] if params[:region].present?
    @initial_city = params[:city] if params[:city].present?
  end

  def past
    events = Event.past.includes(:user, :event_locations).limit(100)
    @events_by_month = events.group_by { |e| e.start_date.beginning_of_month }
  end

  def my_events
    @events = Current.user.events.includes(:event_locations).order(start_date: :desc)
  end

  def show
    @pending_ownership_request = @event.pending_ownership_request_for(Current.user)
  end

  def new
    source_event = copy_source_event
    return if performed?

    unless Current.user.can_create_event?
      redirect_to events_path, alert: "You can only create 10 events in a 24-hour period. Please try again later or ask to become an approved organiser."
      return
    end

    if source_event
      @event = duplicate_event(source_event)
      @submitted_dates = [ duplicate_date(source_event) ]
    else
      @event = Current.user.events.build
      @event.event_locations.build
      @submitted_dates = [ { "start_date" => Date.tomorrow.to_s } ]
    end
  end

  def create
    result = EventCreationService.call(
      user: Current.user,
      event_params: create_event_params,
      dates: dates_params
    )

    if result.success?
      handle_creation_success(result)
    else
      handle_creation_failure(result)
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
    unless can_modify_event?(@event)
      redirect_to root_path, alert: "You are not authorized to modify this event."
    end
  end

  def copy_source_event
    return if params[:copy_from].blank?

    source_event = Event.find(params[:copy_from])
    return source_event if can_modify_event?(source_event)

    redirect_to root_path, alert: "You are not authorized to modify this event."
    nil
  end

  def duplicate_event(source_event)
    attributes = {
      title: source_event.title,
      short_summary: source_event.short_summary,
      cost: source_event.cost,
      event_type: source_event.event_type,
      registration_url: source_event.registration_url,
      region: source_event.region,
      city: source_event.city,
      address: source_event.address,
      event_locations_attributes: source_event.event_locations.map.with_index do |location, index|
        {
          region: location.region,
          city: location.city,
          position: index
        }
      end
    }

    if Current.user.admin?
      attributes[:source] = source_event.source
      attributes[:source_url] = source_event.source_url
    end

    Current.user.events.build(attributes).tap do |event|
      event.description = source_event.description.body.to_s
      event.event_locations.build if event.event_locations.empty?
    end
  end

  def duplicate_date(source_event)
    {
      "start_date" => source_event.start_date&.to_s,
      "end_date" => source_event.end_date&.to_s,
      "start_time" => source_event.start_time&.strftime("%H:%M"),
      "end_time" => source_event.end_time&.strftime("%H:%M")
    }
  end

  def handle_creation_success(result)
    if result.single?
      event = result.events.first
      msg = event.approved? ? "Event created successfully!" : "Event created! It will appear on the events list once approved by an admin."
      redirect_to event, notice: msg
    else
      redirect_to my_events_events_path, notice: "#{result.events.length} events created successfully!"
    end
  end

  def handle_creation_failure(result)
    @event = result.display_event
    @submitted_dates = result.events.any? ? dates_params.map(&:to_h) : [ {} ]
    render :new, status: :unprocessable_entity
  end

  def can_modify_event?(event)
    logged_in? && (Current.user.admin? || event.owned_by?(Current.user))
  end

  def event_params
    params.require(:event).permit(
      *(permitted_event_attributes + [ :start_date, :end_date, :start_time, :end_time ]),
      event_locations_attributes: [ :id, :region, :city, :position, :_destroy ]
    )
  end

  def create_event_params
    params.require(:event).permit(
      *permitted_event_attributes,
      event_locations_attributes: [ :id, :region, :city, :position, :_destroy ]
    )
  end

  def dates_params
    raw = params.dig(:event, :dates)
    return [] if raw.blank?
    raw.values.map { |d| d.permit(:start_date, :end_date, :start_time, :end_time) }
  end

  def permitted_event_attributes
    attributes = [
      :title, :description, :short_summary, :cost, :event_type,
      :registration_url, :region, :city, :address
    ]

    attributes.concat([ :source, :source_url ]) if Current.user.admin?
    attributes
  end
end
