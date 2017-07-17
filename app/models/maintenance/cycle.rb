class Maintenance::Cycle < ActiveRecord::Base
  belongs_to :user
  belongs_to :property
  has_many :maintenance_records, foreign_key: :cycle_id, class_name: 'Maintenance::MaintenanceRecord'

  FREQUENCIES = 1..12
  CYCLE_TYPES = [TYPE_ROOM=:room, TYPE_PUBLIC_AREA=:public_area]
  CYCLE_DESC = {
    TYPE_ROOM.to_s => 'Guest Room PM',
    TYPE_PUBLIC_AREA.to_s => 'Public Area PM'
  }

  validates_presence_of :year, :frequency_months, :start_month, :cycle_type
  validates_uniqueness_of :start_month, scope: [:year, :cycle_type, :property]
  validates :user, presence: true
  validates :property, presence: true

  default_scope { where(property_id: Property.current_id).order(:created_at) }
  scope :by_year, -> (year) { where(year: year).order(:start_month) }
  scope :by_cycle_type, -> (cycle_type) { where(cycle_type: cycle_type) }

  def is_over?
    DateTime.new(year, start_month, 1).months_since(frequency_months) <= Date.today
  end

  def cycle_type_desc
    CYCLE_DESC[cycle_type]
  end

  def is_current_cycle?
    start_date = DateTime.new(year, start_month, 1)
    start_date <= Date.today && start_date.months_since(frequency_months) > Date.today
  end
  
  def ordinal_number
    total_cycles_in_maintenance_year = 12 / self.frequency_months 
    self.class.where(frequency_months: self.frequency_months, cycle_type: self.cycle_type).count % total_cycles_in_maintenance_year
  end

  def start_quarter
    self.class.by_year(self.year).by_cycle_type(self.cycle_type).minimum(:start_month) / 3
  end

  def days_to_finish
    cycle_end_date = DateTime.new(year, start_month, 1) + frequency_months.month
    (cycle_end_date - Date.current).to_i
  end

  def period
    start_date = Date.new(year, start_month, 1)
    end_date = start_date + (frequency_months - 1).months
    start_format = (start_date.year == end_date.year ? '%b' : '%b %Y')
    start_date == end_date ? end_date.strftime('%b %Y') : "#{start_date.strftime(start_format)} ~ #{end_date.strftime('%b %Y')}"
  end

  def rooms_remaining
    # If rooms have been maintained in current cycle, treats it as completed
    # This scenario is for previous.rooms_remaining
    if Maintenance::Cycle.current.id == id
      current_finished_maintainable_ids = []
    else
      current_finished_maintainable_ids = Maintenance::Cycle.current.maintenance_records.for_rooms.finished.pluck(:maintainable_id)
    end
    Maintenance::Room.where.not(id: maintenance_records.for_rooms.finished.pluck(:maintainable_id) + current_finished_maintainable_ids )
  end

  def rooms_in_progress
    Maintenance::Room.where(id: maintenance_records.for_rooms.in_progress.pluck(:maintainable_id) )
  end

  def rooms_completed
    Maintenance::Room.where(id: maintenance_records.for_rooms.finished.pluck(:maintainable_id))
  end

  def rooms_inspected
    Maintenance::Room.where(id: maintenance_records.for_rooms.completed.pluck(:maintainable_id))
  end

  def number_of_rooms_to_inspect
    Property.current.target_inspection_count - rooms_inspected.count
  end

  def rooms_to_inspect
    inspect_count = Property.current.target_inspection_count
    in_inspection = maintenance_records.for_rooms.in_inspection.pluck(:maintainable_id, :updated_at, :id)
    completed = maintenance_records.for_rooms.completed.pluck(:maintainable_id, :inspected_on, :id)
    to_inspect = maintenance_records.for_rooms.to_inspect
                     .pluck(:maintainable_id, :completed_on, :id)
                     .sort_by {|r| r[1]}.reverse!
                     .uniq {|r| r[0]}
    completed_ids = completed.map { |record| record[0] }
    to_inspect = to_inspect.delete_if { |record| completed_ids.include?(record[0]) }
    in_inspection = in_inspection.delete_if { |record| completed_ids.include?(record[0]) }
    rest_count = inspect_count - in_inspection.count - completed.count
    rest = if rest_count <= 0
             []
           else
             rest_count > to_inspect.count ? to_inspect : to_inspect.sample(rest_count)
           end
    list = in_inspection.sort_by { |e| e[1] }.reverse! + rest.sort_by { |e| e[1] } + completed.sort_by { |e| e[1] }.reverse!
    Maintenance::Room.with_maintenance_info list.collect{|id| [id[0], id[2]] }
  end

  def public_areas_to_inspect
    in_inspection = maintenance_records.for_public_areas.in_inspection.pluck(:maintainable_id, :updated_at, :id)
    completed = maintenance_records.for_public_areas.completed.pluck(:maintainable_id, :inspected_on, :id)
    to_inspect = maintenance_records.for_public_areas.to_inspect
                     .pluck(:maintainable_id, :completed_on, :id)
                     .sort_by {|r| r[1]}.reverse!
                     .uniq {|r| r[0]}
    completed_ids = completed.map { |record| record[0] } + in_inspection.map { |record| record[0] }
    to_inspect.reject! { |record| completed_ids.include?(record[0]) }
    list = in_inspection.sort_by { |e| e[1] }.reverse! + to_inspect.sort_by { |e| e[1] } + completed.sort_by { |e| e[1] }.reverse!
    Maintenance::PublicArea.with_maintenance_info list.collect{|id| [id[0], id[2]] }
  end

  def rooms_completed_percent
    Maintenance::Room.count == 0 ? 0 : (rooms_completed.count * 100 / Maintenance::Room.count).round
  end
  
  def public_areas_remaining
    # If rooms have been maintained in current cycle, treats it as completed
    # This scenario is for previous.rooms_remaining
    if Maintenance::Cycle.current(:public_area).id == id
      current_finished_maintainable_ids = []
    else
      current_finished_maintainable_ids = Maintenance::Cycle.current(:public_area)
                                                            .maintenance_records
                                                            .for_public_areas
                                                            .finished
                                                            .pluck(:maintainable_id)
    end
    finished_ids = maintenance_records.for_public_areas.finished.pluck(:maintainable_id) + current_finished_maintainable_ids
    Maintenance::PublicArea.where.not(id: finished_ids).active
  end

  def public_areas_in_progress
    Maintenance::PublicArea.where(id: maintenance_records.for_public_areas.in_progress.pluck(:maintainable_id) ).active
  end

  def public_areas_completed
    Maintenance::PublicArea.where(id: maintenance_records.for_public_areas.finished.pluck(:maintainable_id)).active
  end

  def public_areas_inspected
    Maintenance::PublicArea.where(id: maintenance_records.for_public_areas.completed.pluck(:maintainable_id)).active
  end

  def self.current(cycle_type = 'room')
    by_cycle_type(cycle_type).last
  end

  def self.previous(cycle_type = 'room')
    return nil if by_cycle_type(cycle_type).count < 2
    by_cycle_type(cycle_type).order(:created_at).last(2).first
  end

  def pm_start_month
    sm = start_month - (ordinality_number - 1) * frequency_months
    sm = sm + 12 if sm < 0
    sm
  end

  def self.generate_first_cycle(params)
    current_month = Date.today.month
    start_month = params[:start_month].to_i
    frequency_months = params[:frequency].to_i
    while current_month >= start_month do
      start_month += frequency_months
    end
    start_month -= frequency_months

    cycles_in_a_year  = 12 / frequency_months
    ordinality_number_idx = (start_month - params[:start_month].to_i) / frequency_months
    ordinality_number = ordinality_number_idx.divmod(cycles_in_a_year).last + 1

    cycle = Maintenance::Cycle.new
    cycle.ordinality_number = ordinality_number
    cycle.start_month = start_month
    cycle.frequency_months = frequency_months
    cycle.user_id = params[:user_id]
    cycle.year = Date.today.year
    cycle.cycle_type = params[:cycle_type]
    cycle.save

    cycle
  end
  
  # generates next cycle record. Called by recurring job
  def self.generate_next_cycle(cycle_type)
    current_cycle = current(cycle_type)
    return current_cycle unless current_cycle.is_over?
    total_cycles_in_a_year = 12 / current_cycle.frequency_months
    new_cycle = current_cycle.dup
    new_cycle.ordinality_number = current_cycle.ordinality_number.modulo(total_cycles_in_a_year) + 1

    new_cycle_start_date = Date.new(current_cycle.year, current_cycle.start_month) + current_cycle.frequency_months.months
    new_cycle.year = new_cycle_start_date.year 
    new_cycle.start_month = new_cycle_start_date.month

    new_cycle.save
    new_cycle
  end
end
