class RegistrationsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    # v3 check
    captcha_success = verify_recaptcha(action: 'signup', minimum_score: 0.5, secret_key: ENV['RECAPTCHA_V3_SECRET_KEY'], model: @user)
    
    # Fallback to v2 if v3 fails
    unless captcha_success
      captcha_success = verify_recaptcha(secret_key: ENV['RECAPTCHA_V2_SECRET_KEY'], model: @user)
      # If v2 succeeds, clear the error added by v3 failure so validation passes purely on captcha
      @user.errors.delete(:base) if captcha_success
      
      # If still not successful (v2 failed or wasn't present), show checkbox
      @show_checkbox_recaptcha = true unless captcha_success
    end

    captcha_valid = !recaptcha_enabled? || captcha_success

    if captcha_valid && @user.save
      start_new_session_for(@user)
      redirect_to root_path, notice: "Account created successfully! Welcome to NZ Tech Events."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation, :name)
  end
end
