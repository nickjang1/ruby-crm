class Users::ConfirmationsController < Devise::ConfirmationsController
  def show
    if params[:confirmation_token].present?
      @original_token = params[:confirmation_token]
    elsif params[resource_name].try(:[], :confirmation_token).present?
      @original_token = params[resource_name][:confirmation_token]
    end

    self.resource = resource_class.find_by_confirmation_token Devise.token_generator.digest(self, :confirmation_token, @original_token)
    super if resource.nil? or resource.confirmed?
  end

  def confirm
    Property.current_id = nil
    digested_token = Devise.token_generator.digest(self, :confirmation_token, params[:confirmation_token])
    self.resource = resource_class.find_by_confirmation_token! digested_token
    resource.assign_attributes(permitted_params)

    if resource.valid? && resource.password_match?
      self.resource.confirm!
      set_flash_message :notice, :confirmed
      sign_in resource_name, resource
      redirect_to after_sign_in_path_for(resource)
    else
      @original_token = params[:confirmation_token]
      render :action => 'show'
    end
  end

  private
  def permitted_params
    params.require(resource_name).permit(:confirmation_token, :password, :password_confirmation)
  end
end
