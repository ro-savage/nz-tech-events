class Admin::EventsController < ApplicationController
  before_action :require_login
  before_action :require_admin

  def pending
    @events = Event.pending_approval.order(created_at: :desc).includes(:user)
  end

  def approve
    @event = Event.find(params[:id])
    @event.update(approved: true)
    redirect_to admin_pending_events_path, notice: "Event approved successfully."
  end

  def reject
    @event = Event.find(params[:id])
    @event.destroy
    redirect_to admin_pending_events_path, notice: "Event rejected and deleted."
  end

  private

  def require_admin
    unless Current.user&.admin?
      redirect_to root_path, alert: "You are not authorized to access this page."
    end
  end
end
