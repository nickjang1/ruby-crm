class Maintenance::ChecklistItemMaintenancePolicy < Maintenance::BasePolicy

  %w(single_click_pm).each do |action|
    define_method("#{action}?") { @permission_attributes.map(&:action).include?(action) }
  end

end