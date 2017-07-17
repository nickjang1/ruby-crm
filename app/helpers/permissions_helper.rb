module PermissionsHelper

  def permission_value(permissions, attribute, option = nil)
    permitted = permissions.where(permission_attribute_id: attribute.id).first
    permitted.present? && (option.present? ? (permitted.options || []).include_in_hash?(option[:option]) : true)
  end

  def permission_option(permissions, attribute, option)
    permitted = permissions.where(permission_attribute_id: attribute.id).first
    (permitted.present? && (permitted.options || []).select_in_hash(option)) || []
  end

  def item_name(item, option = nil)
    "[#{item.subject}][#{item.action}]" + (option ? "[#{option[:option]}]" : '')
  end

  def item_id(item, option = nil)
    "#{item.subject}_#{item.action}" + (option ? "_#{option[:option]}" : '')
  end

  def priority_path
    if policy(:access).work_order? && policy(Maintenance::WorkOrder).index?
      maintenance_work_orders_path
    else
      dashboard_path
    end
  end

  def border_colors
    ['border-inverse', 'border-success', 'border-danger', 'border-primary', 'border-teal', 'border-info']
  end
end
