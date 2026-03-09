class AdminMailer < ApplicationMailer
  def pending_events_reminder(admin_user, pending_events_count)
    @admin_user = admin_user
    @pending_events_count = pending_events_count
    @pending_events_url = admin_pending_events_url

    mail(
      to: admin_user.email_address,
      subject: "#{pending_events_count} pending #{'event'.pluralize(pending_events_count)} awaiting approval"
    )
  end
end
