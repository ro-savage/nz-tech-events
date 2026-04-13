class CleanupExpiredSessionsJob < ApplicationJob
  queue_as :default

  SESSION_EXPIRY = 30.days

  def perform
    # delete_all issues a single DELETE — Session has no callbacks or dependents
    expired_count = Session.where("updated_at <= ?", SESSION_EXPIRY.ago).delete_all
    Rails.logger.info "[CleanupExpiredSessionsJob] Deleted #{expired_count} expired sessions"
  end
end
