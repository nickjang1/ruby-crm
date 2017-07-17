class Corporate::BaseController < ApplicationController
  # layout 'corporate'
  before_filter :authenticate_user!
  before_action :check_permissions

  private

  def check_permissions
    authorize! :access_corporate_app, current_user
  end
end

