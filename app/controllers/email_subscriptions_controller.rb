class EmailSubscriptionsController < ApplicationController
  def new
    @email_subscription = EmailSubscription.new
  end

  def create
    @email_subscription = EmailSubscription.new(email_subscription_params)

    if @email_subscription.save
      redirect_to root_path, notice: "You've been subscribed to weekly #{@email_subscription.region_display} tech event updates!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @email_subscription = EmailSubscription.find_by(unsubscribe_token: params[:token])

    if @email_subscription
      @region_display = @email_subscription.region_display
      @email_subscription.destroy
    else
      redirect_to root_path, alert: "Invalid or expired unsubscribe link."
    end
  end

  private

  def email_subscription_params
    params.require(:email_subscription).permit(:email_address, :region)
  end
end
