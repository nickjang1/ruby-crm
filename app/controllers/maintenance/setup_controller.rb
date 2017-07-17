class Maintenance::SetupController < Maintenance::BaseController
  add_breadcrumb I18n.t('controllers.maintenance.setup.index'), :maintenance_setup_path
  before_filter :authorize_pm_setup

  def index
  end

  def rooms
    add_breadcrumb t('controllers.maintenance.setup.rooms')
    @current_cycle = current_cycle(:room)
  end
  
  def public_areas
    add_breadcrumb t('controllers.maintenance.setup.public_areas')
    @current_cycle = current_cycle(:public_area)
  end

  def equipment
    add_breadcrumb t('controllers.maintenance.setup.equipment')
  end
end
