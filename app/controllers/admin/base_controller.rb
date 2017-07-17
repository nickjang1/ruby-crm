class Admin::BaseController < ActionController::Base
  protect_from_forgery
  before_filter :authenticate_admin!

  layout 'admin'

  protected

  def after_sign_in_path_for(admin)
    sign_in_url = url_for(action: 'new', controller: 'sessions', only_path: false, protocol: 'http')
    if request.referer == sign_in_url
      super
    else
      stored_location_for(user) || request.referer || admin_root_path
    end
  end
end