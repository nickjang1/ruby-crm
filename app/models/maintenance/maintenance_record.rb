class Maintenance::MaintenanceRecord < ActiveRecord::Base
  self.table_name = :maintenance_records
  include PublicActivity::Common
  include ::StampUser

  STATUSES = [STATUS_FINISHED=:finished, STATUS_IN_PROGRESS=:in_progress, STATUS_IN_INSPECTION=:inspection, STATUS_COMPLETED=:completed]

  belongs_to :user
  belongs_to :property
  belongs_to :cycle, foreign_key: :cycle_id, class_name: 'Maintenance::Cycle'
  belongs_to :maintainable, polymorphic: true
  belongs_to :inspected_by, foreign_key: :inspected_by_id, class_name: 'User'
  belongs_to :completed_by, foreign_key: :completed_by_id, class_name: 'User'
  belongs_to :equipment_checklist_group, class_name: 'Maintenance::EquipmentChecklistItem', foreign_key: :equipment_checklist_group_id
  has_many :checklist_item_maintenances, foreign_key: :maintenance_record_id, class_name: 'Maintenance::ChecklistItemMaintenance', dependent: :destroy
 
  default_scope { where(property_id: Property.current_id) }
  scope :finished, ->{ where(status: [STATUS_FINISHED, STATUS_IN_INSPECTION, STATUS_COMPLETED]) }
  scope :in_progress, ->{ where(status: STATUS_IN_PROGRESS) }
  scope :completed, -> { where(status: STATUS_COMPLETED) }
  scope :to_inspect, -> { where(status: STATUS_FINISHED) }
  scope :in_inspection, -> { where(status: STATUS_IN_INSPECTION) }
  scope :for_rooms, -> { where(maintainable_type: 'Maintenance::Room')}
  scope :for_public_areas, -> { where(maintainable_type: 'Maintenance::PublicArea')}
  scope :for_equipments, -> { where(maintainable_type: 'Maintenance::Equipment')}
  scope :for_current_cycle, -> (cycle_type = 'room') { where(cycle_id: Maintenance::Cycle.current(cycle_type).id) }
  scope :for_cycle, -> (cycle_id) { where(cycle_id: cycle_id).first }
  scope :by_cycle, -> (cycle_id) { where(cycle_id: cycle_id) }
  scope :by_type, -> (type) { where(maintainable_type: type) }
  scope :by_status, -> (status) { where(status: status) }

  before_save :stamp_whodunnit
  after_save :create_pm_activity

  def in_inspection?
    status == STATUS_IN_INSPECTION.to_s
  end

  def completed?
    status == STATUS_COMPLETED.to_s
  end

  def cancel_inspection
    checklist_item_maintenances.map(&:cancel_inspection)
    self.status = STATUS_FINISHED
    self.save
  end

  def maintainable_name
    maintainable.to_s
  end

  def minutes_to_complete
    (completed_on - created_at).to_i / 60
  end

  def maintainable_type_short
    maintainable_type.underscore[12..-1] # maintenance/room -> room
  end

  def stamp_whodunnit
    if status_changed?
      case status.to_sym
        when STATUS_FINISHED
          self.completed_by_id = self.updated_by
          self.completed_on = Time.current
        when STATUS_COMPLETED
          self.inspected_by_id = self.updated_by
          self.inspected_on = Time.current
      end
    end
  end

  def create_pm_activity
    if status_changed?
      case status.to_sym
        when STATUS_IN_PROGRESS
          create_activity key: "#{maintainable_type_short}.pm_started", recipient: Property.current, owner: user
        when STATUS_FINISHED
          create_activity key: "#{maintainable_type_short}.pm_finished", recipient: Property.current, owner: completed_by
        when STATUS_COMPLETED
          create_activity key: "#{maintainable_type_short}.pm_inspected", recipient: Property.current, owner: inspected_by
      end
    end
  end
end
