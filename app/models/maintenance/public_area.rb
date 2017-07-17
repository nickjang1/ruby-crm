class Maintenance::PublicArea < ActiveRecord::Base
  include RankedModel
  ranks :row_order, scope: :active
  
  belongs_to :user
  belongs_to :property
  has_many :maintenance_records, as: :maintainable
  has_many :maintenance_checklist_items, -> { rank(:public_area_row_order) } ,foreign_key: :public_area_id, :class_name => 'Maintenance::ChecklistItem'
  default_scope { where(property_id: Property.current_id).rank(:row_order) }

  scope :active, -> { where(is_deleted: false) }

  def self.areas_with_subcategories
    active.map do |area|
      {id: area.id, name: area.name, subcategories: area.maintenance_checklist_items.active.rank(:public_area_row_order).select([:id, :name]) }
    end
  end
  
  def checklist_items
    maintenance_checklist_items.active.rank(:public_area_row_order).select([:id, :name])
  end
  
  def self.by_progress
    public_areas = []
    all.each do |area|
      area_hash = JSON::parse(area.to_json)
      area_hash.merge!(maintenance_in_progress: area.is_currently_in_progress?)
      area_hash.merge!(done_percentage: area.currently_maintained_percentage) if area.is_currently_in_progress?
      public_areas << area_hash
    end
    public_areas
  end

  def self.with_maintenance_info(ids)
    public_areas = []
    cycles_count = Property.current.target_inspection_percent > 0 ? 100 / Property.current.target_inspection_percent : 0
    ids.each do |info|
      area = Maintenance::PublicArea.active.find_by id: info[0]
      next if area.nil?
      area_hash = JSON.parse area.to_json
      maintenance_record = area.maintenance_records.for_current_cycle(:public_area).find info[1] if Maintenance::Cycle.current(:public_area)
      if maintenance_record
        area_hash.merge! completed_by: maintenance_record.completed_by.try(:name)
        area_hash.merge! completed_on: I18n.l(maintenance_record.completed_on, format: :date_and_am_pm)
        area_hash.merge! in_inspection: maintenance_record.in_inspection?
        area_hash.merge! completed: maintenance_record.completed?
        area_hash.merge! fixed: maintenance_record.checklist_item_maintenances.fixed.count
        area_hash.merge! work_orders: maintenance_record.checklist_item_maintenances.issues.count
      end
      last_inspection = area.maintenance_records.completed.last
      if last_inspection.present?
        area_hash.merge! ever_inspected: last_inspection.present?
        area_hash.merge! last_inspected_on: I18n.l(last_inspection.inspected_on, format: :medium)
        area_hash.merge! last_inspected_by: last_inspection.inspected_by.try(:name)
        area_hash.merge! inspected_count: area.maintenance_records.completed.where.not(cycle: Maintenance::Cycle.current(:public_area)).count

        area_hash.merge! cycles_count: [cycles_count, 2].max
      end
      public_areas << area_hash
    end
    public_areas
  end
  
  def is_currently_in_progress?
    current_maintenance_record.present?
  end
  
  def current_maintenance_record
    @result ||= maintenance_records.in_progress.for_current_cycle(:public_area).first if Maintenance::Cycle.current(:public_area)
  end
  
  def currently_maintained_percentage
    if is_currently_in_progress?
      return 100 if maintenance_checklist_items.active.count.zero?
      (current_maintenance_record.checklist_item_maintenances.active.count.to_f * 100 / maintenance_checklist_items.active.count).round
    else
      0
    end
  end
  
  def start_maintenance(user)
    record = maintenance_records.for_current_cycle(:public_area).in_progress.first
    if record.nil?
      record = maintenance_records.build(cycle_id: Maintenance::Cycle.current(:public_area).id)
      record.status = Maintenance::MaintenanceRecord::STATUS_IN_PROGRESS
      record.started_at = Time.now
      record.user = user
      record.save
    end
    record
  end

  def start_inspection
    record = maintenance_records.for_current_cycle(:public_area).in_inspection.first
    if record.nil?
      record = maintenance_records.for_current_cycle(:public_area).to_inspect.last
      record.status = Maintenance::MaintenanceRecord::STATUS_IN_INSPECTION
      record.save
    end
    record
  end

  def to_s
    name
  end
  
end
