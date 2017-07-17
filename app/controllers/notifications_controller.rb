class NotificationsController < ApplicationController

  respond_to :json

  def index
    if params[:unread] == true
      @notifications = current_user.notifications.unread.decorate
    else
      @notifications = current_user.notifications.decorate
    end
  end

  def update
    if current_user.notifications.find(params[:id]).update_attributes(read: params[:read] || true)
      render :nothing => true, status: 200
    else
      render :nothing => true, status: 204
    end
  end

  def destroy
    current_user.notifications.where(id: params[:ids]).destroy_all
    render :nothing => true, status: 200
  end

end
