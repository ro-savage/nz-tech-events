class ApplicationController < ActionController::Base
  include Authentication
  allow_unauthenticated_access
  before_action :restore_session

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :logged_in?, :pending_events_count, :pending_ownership_requests_count, :recaptcha_enabled?

  private

  # Always try to restore the session, even on public pages
  def restore_session
    resume_session
  end

  def logged_in?
    Current.user.present?
  end

  def pending_events_count
    @pending_events_count ||= Event.pending_approval.count if Current.user&.admin?
  end

  def pending_ownership_requests_count
    @pending_ownership_requests_count ||= OwnershipRequest.pending.count if Current.user&.admin?
  end

  def recaptcha_enabled?
    ENV["ENABLE_RECAPTCHA"] == "true"
  end

  def require_login
    unless logged_in?
      redirect_to new_session_path, alert: "Please sign in to continue."
    end
  end

  def require_admin
    unless Current.user&.admin?
      redirect_to root_path, alert: "You are not authorized to access this page."
    end
  end
end
