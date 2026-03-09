class OwnershipRequestsController < ApplicationController
  before_action :require_login
  before_action :set_event
  before_action :ensure_requestable!, only: [ :new, :create ]

  def new
    @ownership_request = build_ownership_request
  end

  def create
    @ownership_request = build_ownership_request

    if @ownership_request.save
      notify_admins(@ownership_request)
      redirect_to @event, notice: "Ownership request submitted. An admin will review it shortly."
    else
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    @ownership_request = build_ownership_request
    @ownership_request.errors.add(:base, "You already have a pending ownership request for this event")
    render :new, status: :unprocessable_entity
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def ensure_requestable!
    return redirect_to(@event, alert: "You already own this event.") if @event.owned_by?(Current.user)
    return unless @event.pending_ownership_request_for(Current.user)

    redirect_to @event, alert: "You already have a pending ownership request for this event."
  end

  def ownership_request_params
    params.fetch(:ownership_request, {}).permit(:reason)
  end

  def build_ownership_request
    Current.user.ownership_requests.build(ownership_request_params.merge(event: @event))
  end

  def notify_admins(ownership_request)
    User.where(admin: true).find_each do |admin_user|
      OwnershipRequestMailer.new_request(ownership_request, admin_user).deliver_later
    end
  end
end
