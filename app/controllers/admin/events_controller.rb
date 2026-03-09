class Admin::EventsController < ApplicationController
  before_action :require_login
  before_action :require_admin

  def pending
    @events = Event.pending_approval.order(created_at: :desc).includes(:user)
  end

  def approve
    @event = Event.find(params[:id])
    @event.update(approved: true)
    EventMailer.approved(@event).deliver_later unless @event.user.approved_organiser?
    redirect_to admin_pending_events_path, notice: "Event approved successfully."
  end

  def reject
    @event = Event.find(params[:id])
    @event.destroy
    redirect_to admin_pending_events_path, notice: "Event rejected and deleted."
  end
end
