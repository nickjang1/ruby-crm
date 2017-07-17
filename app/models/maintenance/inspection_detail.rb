class Maintenance::InspectionDetail < ActiveRecord::Base

  belongs_to :work_order, class_name: 'Maintenance::WorkOrder', foreign_key: :work_order_id
  belongs_to :checklist_item_maintenance, class_name: 'Maintenance::ChecklistItemMaintenance', foreign_key: :checklist_item_maintenance_id

end