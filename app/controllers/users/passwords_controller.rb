class Users::PasswordsController < Devise::PasswordsController

  def create
    self.resource = User.find_for_database_authentication(resource_params)
    if self.resource.try(:username) == resource_params[:login]
      flash[:alert] = "Please contact your GM/Admin for reseting your password."
      respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name))
    else
      params[:user][:email] = params[:user][:login]
      super
    end
  end

  protected

  def after_resetting_password_path_for(resource)
    authenticated_root_path
  end

end
