class OauthCallbacksController < ApplicationController
  def google_oauth2
    auth = request.env["omniauth.auth"]

    # Find existing user by Google UID or email
    user = User.find_by(google_uid: auth["uid"]) ||
           User.find_by(email_address: auth["info"]["email"])

    if user
      # Update Google info if linking existing email account
      unless user.google_uid
        user.update(
          google_uid: auth["uid"],
          avatar_url: auth["info"]["image"]
        )
      end
      # Update name if not set
      user.update(name: auth["info"]["name"]) if user.name.blank?
    else
      # Create new user from Google
      user = User.create!(
        email_address: auth["info"]["email"],
        name: auth["info"]["name"],
        google_uid: auth["uid"],
        avatar_url: auth["info"]["image"],
        password: SecureRandom.hex(16) # Random password for OAuth users
      )
    end

    start_new_session_for(user)
    redirect_to root_path, notice: "Signed in with Google successfully!"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to new_session_path, alert: "Could not sign in with Google: #{e.message}"
  end

  def failure
    redirect_to new_session_path, alert: "Google authentication failed. Please try again."
  end
end
