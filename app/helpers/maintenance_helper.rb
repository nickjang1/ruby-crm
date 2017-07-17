module MaintenanceHelper

  def work_order_status_label_class(days_opened)
    if days_opened <= 2
      "label label-success"
    elsif days_opened <= 7
      "label label-warning"
    else
      "label label-danger"
    end
  end
  
  def work_order_priority_label_class(priority)
    if priority == "l"
      "text-success"
    elsif priority == "m"
      "text-warning"
    else
      "text-danger"
    end
  end

  def minutes_to_hours(minutes)
    return if minutes.nil?
    minutes % 30 == 0 ? "#{minutes / 60.0} hours" : "#{minutes} minutes"
  end

  def current_cycle_range
    current_cycle = Maintenance::Cycle.current
    start_date = Time.new(current_cycle.year, current_cycle.start_month)
    end_date = (start_date + (current_cycle.frequency_months - 1).months).end_of_month
    "#{start_date.strftime('%b %d')} - #{end_date.strftime('%b %d')}"
  end
  
  def users_in_current_property
    Property.current.users.active.select { |u| u.wo_assignable_id > 0 }.map{ |u| [u.name.titleize, u.id] } + Maintenance::WorkOrder::EXTRA_USERS
  end

  def default_assigned_to_user(work_order)
    if Property.current.users.include?(work_order.assigned_to)
      work_order.assigned_to_id
    else
      work_order.assigned_to_id || Maintenance::WorkOrder::UNASSIGNED
    end
  end

  def work_order_form_data_attributes(wo)
    {
      'permitted-priority' => policy(wo).permitted_attributes.include?(:priority),
      'permitted-status' => policy(wo).permitted_attributes.include?(:status),
      'permitted-assigned-to-id' => policy(wo).permitted_attributes.include?(:assigned_to_id),
      'permitted-due-to-date' => policy(wo).permitted_attributes.include?(:due_to_date),
      'user-permitted-to-edit-closed-wo' => policy(wo).edit_closed?,
      'wo-closed' => wo.closed?
    }
  end

  def properties_filter_class
    current_user.corporate? && current_user.all_properties.count > 0 ? '' : 'hidden'
  end

  def new_work_order_form_title
    @prev_property_id.nil? ? "Add WO for '#{Property.current.name}'" : 'Add Work Order'
  end

  def new_work_order_description_placeholder
    @prev_property_id.nil? ? "Describe the WO for '#{Property.current.name}'" : t('.description_placeholder')
  end

  def work_order_types
    [
      ['All WOs', nil],
      ['Filter WOs for: Room', 'Maintenance::Room'],
      ['Filter WOs for: Public Area', 'Maintenance::PublicArea'],
      ['Filter WOs for: Equipment', 'Maintenance::Equipment'],
      ['Filter WOs for: Other', 'Other']
    ]
  end

  def work_order_status_labels
    {
      Maintenance::WorkOrder::STATUS_OPEN => 'Open',
      Maintenance::WorkOrder::STATUS_WORKING => 'In Progress',
      Maintenance::WorkOrder::STATUS_CLOSED => 'Closed'
    }
  end

  def work_order_assigned_to(work_order)
    if work_order.assigned_to_id == Maintenance::WorkOrder::THIRD_PARTY
      t('reports.work_order_trendings.third_party')
    elsif work_order.assigned_to_id == Maintenance::WorkOrder::UNASSIGNED
      t('reports.work_order_trendings.unassigned')
    elsif work_order.assigned_to
      work_order.assigned_to.name
    else
      ""
    end
  end
end
