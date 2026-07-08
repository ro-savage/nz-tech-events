class RegistrationsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    captcha_success = if recaptcha_enabled?
      passed = verify_recaptcha(
        action: "signup", minimum_score: 0.5,
        secret_key: ENV["RECAPTCHA_V3_SECRET_KEY"]
      )

      unless passed
        passed = verify_recaptcha(secret_key: ENV["RECAPTCHA_V2_SECRET_KEY"])
        @show_checkbox_recaptcha = true unless passed
      end

      passed
    else
      true
    end

    if captcha_success && @user.save
      start_new_session_for(@user)
      redirect_to root_path, notice: "Account created successfully! Welcome to NZ Tech Events."
    else
      unless captcha_success
        @user.errors.add(:base, "reCAPTCHA verification failed, please try again.")
      end
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation, :name)
  end
end
