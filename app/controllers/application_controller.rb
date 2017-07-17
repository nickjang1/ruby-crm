class ApplicationController < ActionController::Base
  include Pundit
  protect_from_forgery
  before_filter :scope_current_property
  before_filter :set_cache_buster

  def current_cycle(cycle_type=:room)
    Maintenance::Cycle.current cycle_type
  end
  
  def previous_cycle(cycle_type)
    Maintenance::Cycle.previous cycle_type
  end
  helper_method :current_cycle
  helper_method :previous_cycle
  helper :all

  protected

  def set_cache_buster
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
  end

  def scope_current_property
    Property.current_id = current_property.try(:id) if user_signed_in?
  end

  rescue_from CanCan::AccessDenied do |e|
    flash[:alert] = e.message

    if request.env["HTTP_REFERER"]
      redirect_to :back
    else
      redirect_to '/'
    end
  end

  rescue_from Pundit::NotAuthorizedError do |e|
    flash[:alert] = 'You are not authorized to access page.'
    respond_to do |format|
      format.any(:all, :json) { render json: 'You cannot perform this action', status: :forbidden }
      format.html { redirect_to request.env["HTTP_REFERER"] ? :back : '/' }
    end
  end

  def user_properties
    @user_properties ||= current_user.all_properties
  end
  helper_method :user_properties

  def current_corporate
    current_user.corporate
  end
  helper_method :current_corporate

  def current_property
    # return nil if current_user.corporate? && session[:property_id].blank?
    if current_user.corporate?
      if session[:property_id]
        return user_properties.where(id: session[:property_id]).first
      else
        return nil
      end
    end

    @current_property = user_properties.where(id: session[:property_id]).first
    @current_property ||= user_properties.first

    raise I18n.t('controllers.application.no_properties_for_user') if @current_property.nil?
    session[:property_id] = @current_property.id
    @current_property
  end
  helper_method :current_property

  def selected_property
    @selected_property ||= Property.first
  end
  helper_method :selected_property

  def after_sign_in_path_for(user)
    devise_urls = [new_user_session_path, user_confirmation_path]
    if user.is_a? Admin
      admin_root_path
    else
      if request.referer && devise_urls.any? { |url| request.referer.index(url).present? }
        super
      else
        session[:property_id] = user.settings['primary_hotel']
        stored_location_for(user) || request.referer || authenticated_root_path
      end
    end
  end

  # use around_filter to render action with scoping property.
  # need to pass param[:property_id]
  def action_with_property
    @prev_property_id = Property.current_id
    property_id = current_user.corporate? ? current_corporate.properties.first.try(:id) : Property.current_id
    Property.current_id = params[:property_id] || property_id
    yield
    Property.current_id = @prev_property_id
  end

  # property timezone
  def property_time_zone(&block)
    Time.use_zone(Property.current.time_zone, &block) if Property.current
  end
end
