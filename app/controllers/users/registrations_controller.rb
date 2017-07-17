class Users::RegistrationsController < Devise::RegistrationsController
  def account_update_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :current_password)
  end
  private :account_update_params

  def destroy
    render nothing: true, status: :forbidden
  end

  protected
    def after_sign_up_path_for(resource)
      signed_in_root_path(resource)
    end

    def after_update_path_for(resource)
      signed_in_root_path(resource)
    end
end
