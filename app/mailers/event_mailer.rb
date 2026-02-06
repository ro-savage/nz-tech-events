class EventMailer < ApplicationMailer
  def approved(event)
    @event = event
    @user = event.user

    mail(
      to: @user.email_address,
      subject: "Your NZ Tech Event has been approved",
      reply_to: "rowan.savage@gmail.com",
      content_type: "text/html"
    )
  end
end
