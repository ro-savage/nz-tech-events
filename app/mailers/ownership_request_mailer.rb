class OwnershipRequestMailer < ApplicationMailer
  def new_request(ownership_request, admin_user)
    @ownership_request = ownership_request
    @event = ownership_request.event
    @requester = ownership_request.requester
    @current_owner = @event.user
    @admin_user = admin_user

    mail(
      to: admin_user.email_address,
      subject: "New ownership request for #{@event.title}",
      reply_to: "rowan.savage@gmail.com",
      content_type: "text/html"
    )
  end

  def approved(ownership_request)
    @ownership_request = ownership_request
    @event = ownership_request.event
    @user = ownership_request.requester

    mail(
      to: @user.email_address,
      subject: "You now own #{@event.title} on NZ Tech Events",
      reply_to: "rowan.savage@gmail.com",
      content_type: "text/html"
    )
  end
end
