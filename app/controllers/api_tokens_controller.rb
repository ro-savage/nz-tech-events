class ApiTokensController < ApplicationController
  before_action :require_login
  before_action :require_organiser_or_admin

  def index
    @tokens = Current.user.api_tokens.order(created_at: :desc)
  end

  def create
    @token = Current.user.api_tokens.build(name: params.dig(:api_token, :name))
    raw_token = @token.generate_token_value

    if @token.save
      flash[:token] = raw_token
      redirect_to api_tokens_path, notice: "Token created. Copy it now — it won't be shown again."
    else
      @tokens = Current.user.api_tokens.order(created_at: :desc)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    token = Current.user.api_tokens.find_by(id: params[:id])

    if token
      token.destroy
      redirect_to api_tokens_path, notice: "Token revoked."
    else
      redirect_to api_tokens_path, alert: "Token not found."
    end
  end

  private

  def require_organiser_or_admin
    unless Current.user.approved_organiser? || Current.user.admin?
      redirect_to root_path, alert: "You are not authorized to access this page."
    end
  end
end
