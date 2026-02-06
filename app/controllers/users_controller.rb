class UsersController < ApplicationController
  before_action :require_login, except: [ :show ]
  before_action :require_admin, except: [ :show ]

  def index
    @users = User.order(created_at: :desc).includes(:events)
  end

  def show
    @user = User.find(params[:id])
    events = @user.events.approved.includes(:event_locations)
    @upcoming_events = events.upcoming
    @past_events = events.past
  end

  def toggle_approved_organiser
    @user = User.find(params[:id])
    @user.update(approved_organiser: !@user.approved_organiser)
    UserMailer.approved_organiser(@user).deliver_later if @user.approved_organiser?

    status = @user.approved_organiser? ? "approved organiser" : "regular user"
    redirect_to users_path, notice: "#{@user.display_name} is now a #{status}."
  end

  def destroy
    @user = User.find(params[:id])

    if @user == Current.user
      redirect_to users_path, alert: "You cannot delete your own account from this page."
      return
    end

    @user.destroy
    redirect_to users_path, notice: "User deleted successfully."
  end

  private

  def require_admin
    unless Current.user&.admin?
      redirect_to root_path, alert: "You are not authorized to access this page."
    end
  end
end
