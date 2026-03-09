class Admin::OwnershipRequestsController < ApplicationController
  before_action :require_login
  before_action :require_admin
  before_action :set_ownership_request, only: [ :approve, :reject ]

  def index
    @ownership_requests = OwnershipRequest.pending_first.includes(:requester, event: :user)
  end

  def approve
    @ownership_request.approve!(Current.user)
    OwnershipRequestMailer.approved(@ownership_request).deliver_later
    redirect_to admin_ownership_requests_path, notice: "Ownership request approved successfully."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to admin_ownership_requests_path, alert: e.record.errors.full_messages.to_sentence.presence || "Ownership request could not be approved."
  end

  def reject
    @ownership_request.reject!(Current.user)
    redirect_to admin_ownership_requests_path, notice: "Ownership request rejected successfully."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to admin_ownership_requests_path, alert: e.record.errors.full_messages.to_sentence.presence || "Ownership request could not be rejected."
  end

  private

  def set_ownership_request
    @ownership_request = OwnershipRequest.find(params[:id])
  end
end
