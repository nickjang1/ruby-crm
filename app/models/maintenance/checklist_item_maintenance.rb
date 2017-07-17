class Maintenance::ChecklistItemMaintenance < ActiveRecord::Base
  STATUSES = [STATUS_NO_ISSUES=:no_issues, STATUS_FIXED=:fixed, STATUS_ISSUES=:issues]

  belongs_to :maintenance_record, foreign_key: :maintenance_record_id, class_name: 'Maintenance::MaintenanceRecord'
  belongs_to :maintenance_checklist_item, class_name: 'Maintenance::ChecklistItem'
  belongs_to :maintenance_equipment_checklist_item, :class_name => 'Maintenance::EquipmentChecklistItem', foreign_key: :maintenance_checklist_item_id
  has_one :work_order, foreign_key: :checklist_item_maintenance_id, class_name: 'Maintenance::WorkOrder', dependent: :destroy
  has_one :inspection_detail, class_name: 'Maintenance::InspectionDetail', foreign_key: :checklist_item_maintenance_id, dependent: :destroy
  has_one :inspection_work_order, through: :inspection_detail, source: :work_order

  scope :no_issues, -> { where(status: STATUS_NO_ISSUES) }
  scope :fixed, -> { where(status: STATUS_FIXED) }
  scope :issues, -> { where(status: STATUS_ISSUES) }
  scope :active, -> { joins(:maintenance_checklist_item).where(maintenance_checklist_item: {is_deleted: false}) }

  def cancel_inspection
    inspection_work_order.destroy if inspection_work_order
  end

  def maintainable_type
    maintenance_record.try(:maintainable_type)
  end

  def checklist_item_name
    if maintainable_type == 'Maintenance::Equipment'
      maintenance_record.try(:maintainable).try(:equipment_type).try(:name)
    else
      maintenance_checklist_item.try(:name)
    end
  end

  def maintainable_name
    maintenance_record.try(:maintainable).try(:to_s)
  end
end
