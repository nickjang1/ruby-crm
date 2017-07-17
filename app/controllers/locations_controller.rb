class LocationsController < TagsController
  add_breadcrumb I18n.t('controllers.locations.locations'), :locations_path, :options => { :title => I18n.t('controllers.locations.locations') }

  before_filter :check_permissions

  private

  def check_permissions
    authorize!(params[:action].to_sym, @tag || Location)
  end
end
