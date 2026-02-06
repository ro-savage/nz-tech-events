class UserMailer < ApplicationMailer
  def approved_organiser(user)
    @user = user

    mail(
      to: @user.email_address,
      subject: "Your NZ Tech Events account has been upgraded",
      reply_to: "rowan.savage@gmail.com",
      content_type: "text/html"
    )
  end
end
