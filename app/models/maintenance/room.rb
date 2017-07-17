class Maintenance::Room < ActiveRecord::Base

  belongs_to :property
  belongs_to :user
  has_many :maintenance_records, as: :maintainable
  has_many :work_orders, as: :maintainable, class_name: 'Maintenance::WorkOrder'

  default_scope { where(property_id: Property.current_id) }
  scope :floors_with_room_count, -> { order(:floor).group(:floor).count}
  scope :rooms_on_floor, ->(floor) { where(floor: floor).order(:room_number).includes(:maintenance_records) }
  scope :last_week, -> { includes(:maintenance_records).where(maintenance_records: {completed_on: (Time.current - 1.weeks).beginning_of_day..Time.current.end_of_day}) }

  validates_presence_of :floor, :room_number
  validates_uniqueness_of :room_number, scope: [:property_id]
  validates :user, presence: true
  validates :property, presence: true

  alias_attribute :name, :room_number

  def self.all_floors
    pluck(:floor).uniq.sort
  end

  # TODO Need to make this more simpler
  def self.by_floors(with_maintenance_record=true)
    floors = []
    all_floors.each do |floor|
      floors << {
        floor: floor,
        rooms: rooms_on_floor(floor).map do |room|
          room_hash = { id: room.id, room_number: room.room_number, maintenance_in_progress: room.is_currently_in_progress? }
          if with_maintenance_record
            room_hash[:done_percentage] = room.currently_maintained_percentage if room.is_currently_in_progress?
            maintenance_record = room.maintenance_records.for_current_cycle.first if Maintenance::Cycle.current.present?
            unless maintenance_record.blank?
              room_hash[:maintenance_record] = {
                id: maintenance_record.id,
                fixed: maintenance_record.checklist_item_maintenances.fixed.count,
                work_orders: maintenance_record.checklist_item_maintenances.issues.count,
                completed_by: maintenance_record.completed_by.try(:name),
                in_inspection: maintenance_record.in_inspection?,
              }
            end
          end
          room_hash
        end
      }
    end
    floors.sort_by! { |f| f[:floor] }
  end

  def self.with_maintenance_info(ids)
    results = []
    ids.each do |info|
      room = Maintenance::Room.find_by id: info[0]
      next if room.nil?
      room_hash = JSON.parse room.to_json
      maintenance_record = room.maintenance_records.for_current_cycle.find(info[1]) if Maintenance::Cycle.current
      if maintenance_record
        room_hash.merge! completed_by: maintenance_record.completed_by.try(:name)
        room_hash.merge! completed_on: I18n.l(maintenance_record.completed_on, format: :date_and_am_pm)
        room_hash.merge! in_inspection: maintenance_record.in_inspection?
        room_hash.merge! completed: maintenance_record.completed?
        room_hash.merge! status: maintenance_record.status
        room_hash.merge! fixed: maintenance_record.checklist_item_maintenances.fixed.count
        room_hash.merge! work_orders: maintenance_record.checklist_item_maintenances.issues.count
      end
      last_inspection = room.maintenance_records.completed.last
      if last_inspection.present?
        room_hash.merge! ever_inspected: last_inspection.present?
        room_hash.merge! last_inspected_on: I18n.l(last_inspection.inspected_on, format: :medium)
        room_hash.merge! last_inspected_by: last_inspection.inspected_by.try(:name)
        room_hash.merge! inspected_count: room.maintenance_records.completed.where.not(cycle: Maintenance::Cycle.current(:room)).count
        cycles_count = Property.current.target_inspection_percent > 0 ? 100 / Property.current.target_inspection_percent : 0
        room_hash.merge! cycles_count: [cycles_count , 2].max
      end
      results << room_hash
    end
    results
  end

  def start_maintenance(user)
    record = maintenance_records.for_current_cycle(:room).in_progress.first
    if record.nil?
      record = maintenance_records.build(cycle_id: Maintenance::Cycle.current.id)
      record.status = Maintenance::MaintenanceRecord::STATUS_IN_PROGRESS
      record.started_at = Time.now
      record.user = user
      record.save
    end
    record
  end

  def start_inspection
    record = maintenance_records.for_current_cycle.in_inspection.first
    if record.nil?
      record = maintenance_records.for_current_cycle.to_inspect.last
      record.status = Maintenance::MaintenanceRecord::STATUS_IN_INSPECTION
      record.save
    end
    record
  end

  def self.room_count
    self.all.count
  end

  def self.any_missed_rooms?
    Maintenance::Cycle.previous.rooms_remaining.any? if Maintenance::Cycle.previous
  end

  def is_currently_in_progress?
    current_maintenance_record.present?
  end
  
  def current_maintenance_record
    @result ||= maintenance_records.in_progress.for_current_cycle.first if Maintenance::Cycle.current
  end

  def latest_maintenance_record
    last_completed = maintenance_records.finished.last
    results = {
        started_by: current_maintenance_record.try(:user).try(:name),
        started_on: current_maintenance_record ? I18n.l(current_maintenance_record.try(:created_at), format: :short) : nil,
        status: current_maintenance_record.try(:status),
        floor: floor,
        room_number: room_number
    }
    if last_completed
      results.merge!({
          completed_by: last_completed.completed_by.try(:name),
          completed_on: I18n.l(last_completed.completed_on, format: :short),
          last_maintained_cycle: last_completed.cycle.ordinality_number
      })
    end

    results
  end

  # returns integer
  def currently_maintained_percentage
    if is_currently_in_progress?
      (current_maintenance_record.checklist_item_maintenances.active.count.to_f * 100 / Maintenance::ChecklistItem.by_type(:rooms).non_areas.active.count).round
    else
      0
    end
  end

  def to_s
    I18n.t('maintenance.work_orders.maintainable.room', room_number: room_number) 
  end
end
