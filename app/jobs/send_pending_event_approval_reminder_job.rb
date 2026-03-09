class SendPendingEventApprovalReminderJob < ApplicationJob
  queue_as :default

  def perform
    pending_events_count = Event.pending_approval.count
    return if pending_events_count.zero?

    User.admins.find_each do |admin_user|
      AdminMailer.pending_events_reminder(admin_user, pending_events_count).deliver_later
    end
  end
end
