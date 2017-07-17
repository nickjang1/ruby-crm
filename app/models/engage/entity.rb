class Engage::Entity < ActiveRecord::Base
  include SentientUser

  self.table_name = "engage_entities"

  belongs_to :property
  belongs_to :room, class_name: 'Maintenance::Room', foreign_key: :room_number, primary_key: :room_number
  belongs_to :created_by, class_name: 'User', foreign_key: :created_by_id
  belongs_to :completed_by, class_name: 'User', foreign_key: :completed_by_id

  validates :property, associated: true
  validates :body, :created_by, presence: true

  ENTITY_TYPES = [ALARM='alarm', PICKUP='pickup', LOST='lost', FOUND='found']

  default_scope { where(property_id: Property.current_id) }
  scope :on_date, -> (date) { where(due_date: date.beginning_of_day..date.end_of_day) }
  scope :alarm, -> (date) {
    alarms = where(entity_type: ALARM).order(due_date: :asc)
    date.today? ? alarms.where('due_date >= ?', date.beginning_of_day) : alarms.on_date(date)
  }
  scope :pickup, -> (date) { where(entity_type: PICKUP) }
  scope :lost, -> (date) { where(entity_type: LOST) }
  scope :found, -> (date) { where(entity_type: FOUND) }

  def complete=(value)
    if value == 'true'
      self.complete!
    else
      self.uncomplete!
    end
  end

  def complete!
    self.completed_at = Time.current
    self.completed_by = User.current
    self.save!
  end

  def uncomplete!
    self.completed_at = nil
    self.completed_by = nil
    self.save!
  end

  def due_date_str
    return nil unless due_date
    return "TODAY" if due_date.today?
    return "TOMORROW" if due_date.to_date == Date.current.tomorrow
    I18n.l(due_date, format: :mini)
  end

  def show_up?(date)
    date.beginning_of_day <= due_date && due_date <= date.end_of_day
  end

  def as_json(options = {})
    {
      id: id,
      body: body,
      room_number: room_number,
      created_at: I18n.l(created_at, format: :date_and_am_pm),
      due_time: !!due_date ? I18n.l(due_date, format: :engage_time) : nil,
      due_date_str: due_date_str,
      due_date_today: !!due_date ? due_date.today? : false,
      due_date_tomorrow: !!due_date ? due_date.to_date == Date.current.tomorrow : false,
      completed_at: !!completed_at ? I18n.l(completed_at, format: :date_and_am_pm) : nil,
      completed_by: completed_by.try(:name),
      show_up: show_up?(options[:date]),
    }
  end
end
