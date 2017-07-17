class Users::SessionsController < Devise::SessionsController
  skip_before_filter :scope_current_property

  def switch_current_property
    if params[:new_property_id] == 'corporate' && current_user.corporate_id?
      session[:property_id] = nil
      flash[:notice] = I18n.t('users.sessions.property_changed_success_message', hotel_name: current_user.corporate.name)
    else
      property = current_user.all_properties.find_by_id(params[:new_property_id])
      if property
        session[:property_id] = property.id
        # Property.current_id   = property.id
        flash[:notice] = I18n.t('users.sessions.property_changed_success_message', hotel_name: property.name)
      else
        flash[:error] = I18n.t('users.sessions.property_changed_error_message')
      end
    end
    redirect_to authenticated_root_path
  end
end
