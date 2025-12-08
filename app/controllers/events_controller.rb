class EventsController < ApplicationController
  before_action :require_login, only: [:new, :create, :edit, :update, :destroy, :my_events]
  before_action :set_event, only: [:show, :edit, :update, :destroy]
  before_action :authorize_owner!, only: [:edit, :update, :destroy]

  def index
    @events = Event.upcoming.includes(:user)
  end

  def past
    @events = Event.past.includes(:user)
  end

  def my_events
    @events = Current.user.events.order(start_date: :desc)
  end

  def show
  end

  def new
    @event = Current.user.events.build
    @event.start_date = Date.tomorrow
  end

  def create
    @event = Current.user.events.build(event_params)

    if @event.save
      redirect_to @event, notice: "Event created successfully!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
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

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def authorize_owner!
    unless logged_in? && @event.owned_by?(Current.user)
      redirect_to root_path, alert: "You are not authorized to modify this event."
    end
  end

  def event_params
    params.require(:event).permit(
      :title, :description, :start_date, :end_date,
      :start_time, :end_time, :cost, :event_type,
      :registration_url, :region, :city, :address
    )
  end

end
