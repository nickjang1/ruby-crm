class PropertySettingsController < ApplicationController
  before_filter :authenticate_user!

  def index
    @role_id = params[:role_id] || Role.first.id
    @department_id = params[:department_id] || Department.order(:name).first.id
    @filter = params[:filter] || 'active'
    authorize :access, :settings?
    add_breadcrumb t("controllers.property_settings.property_settings")
  end
end
