class Maintenance::WorkOrder < ActiveRecord::Base
  include Rails.application.routes.url_helpers
  include PublicActivity::Common
  include ::StampUser

  has_paper_trail :only => [:status]
  acts_as_paranoid

  STATUSES = [STATUS_OPEN=:open, STATUS_CLOSED=:closed, STATUS_WORKING=:working]
  MAINTEINABLE_TYPES = %w(Maintenance::Room Maintenance::PublicArea Maintenance::Equipment) 
  PRIORITIES = %w(high medium low) # h => high, m => medium, l => low
  THIRD_PARTY = -1
  UNASSIGNED = -2
  THIRD_PARTY_NAME = '3rd Party'
  UNASSIGNED_NAME = 'Unassigned'
  EXTRA_IDS = [THIRD_PARTY, UNASSIGNED]
  EXTRA_USERS = [
    [THIRD_PARTY_NAME, THIRD_PARTY],
    [UNASSIGNED_NAME, UNASSIGNED]
  ]

  belongs_to :property
  belongs_to :maintainable, polymorphic: true
  belongs_to :checklist_item_maintenance, foreign_key: :checklist_item_maintenance_id, class_name: 'Maintenance::ChecklistItemMaintenance'
  belongs_to :opened_by, foreign_key: :opened_by_user_id, class_name: 'User'
  belongs_to :closed_by, foreign_key: :closed_by_user_id, class_name: 'User'
  belongs_to :updator, foreign_key: :updated_by, class_name: 'User'
  belongs_to :assigned_to, class_name: 'User'
  has_many :attachments, class_name: 'Maintenance::Attachment', as: :attachmentable
  has_many :messages, as: :messagable
  has_many :materials, class_name: 'Maintenance::Material', foreign_key: :work_order_id
  has_many :material_items, class_name: 'Item', through: :materials, source: :item

  scope :opened, -> { where(status: STATUS_OPEN) }
  scope :closed, -> { where(status: STATUS_CLOSED) }
  scope :active, -> { where.not(status: STATUS_CLOSED) }
  scope :unassigned, -> { where(assigned_to_id: UNASSIGNED) }
  scope :by_assignee, -> (assigned_to) { where(assigned_to_id: assigned_to) }

  accepts_nested_attributes_for :checklist_item_maintenance
  accepts_nested_attributes_for :attachments, :allow_destroy => true

  before_update :update_closed_at
  before_save :set_default_values
  after_save :send_notification_and_mail_to_assignee
  after_save :create_wo_activity

  def self.default_scope
    where(property_id: Property.current_id).where(deleted_at: nil)
  end

  def self.by_priority
    ret = 'CASE'
    PRIORITIES.map { |p| p[0] }.each_with_index do |p, i|
      ret << " WHEN priority = '#{p}' THEN #{i}"
    end
    ret << ' END'
  end
  scope :order_by_priority, -> { order(by_priority) }

  def self.by_departments(departments, sql = nil)
    user_ids = DepartmentsUser.where(department_id: departments).pluck(:user_id)
    all.where(
      "assigned_to_id in (?) or opened_by_user_id in (?) #{'OR ' + sql if sql}", user_ids, user_ids
    )
  end

  def self.by_filter(filter)
    records = all
    records = records.send filter[:status] if filter[:status]
    records = records.where(
      closed_at: Date.parse(filter[:from]).beginning_of_day..Date.parse(filter[:to]).end_of_day
    ) if filter[:from] && filter[:to]
    records = records.where(maintainable_type: filter[:wo_type]) if filter[:wo_type]
    records
  end

  def closed?
    status == STATUS_CLOSED.to_s
  end

  def days_opened
    (Date.current - opened_at.to_date).to_i + 1
  end

  def days_elapsed
    (closed_at.to_date - opened_at.to_date).to_i + 1 if closed? && closed_at && opened_at
  end

  def checklist_item_name
    if maintainable_type == 'Maintenance::Equipment'
      maintainable.try(:equipment_type).try(:name)
    else
      checklist_item_maintenance.try(:maintenance_checklist_item).try(:name)
    end
  end

  def location_name
    maintainable_id.present? && maintainable.to_s + ( checklist_item_name ? " | #{checklist_item_name}" : '') || other_maintainable_location
  end

  def location_detail
    maintainable_detail = if maintainable_id.present?
                            if maintainable.is_a? Maintenance::Room
                              maintainable_name
                            elsif maintainable.is_a? Maintenance::PublicArea
                              "Public Area '#{maintainable_name}'"
                            elsif maintainable.is_a? Maintenance::Equipment
                              "Equipment '#{maintainable_name}'"
                            end
                          else
                            other_maintainable_location
                          end
    [maintainable_detail, checklist_item_name].reject(&:blank?).join(" / ")
  end

  # returns:
  # { "Maintenance::Room" => { 1 => "101",  2 => "102" }, "Maintenance::PublicArea" => { 1 => "Conference Room A", 4 => "Gym" }}
  def self.maintenable_entities
    Maintenance::WorkOrder::MAINTEINABLE_TYPES.inject({}) do |hash, mt|
      hash[mt] = mt.constantize.all.inject({}){ |mt_hash, mt_record| mt_hash[mt_record.id]= mt_record.name; mt_hash }
      hash
    end
  end

  def maintainable_name
    maintainable_id.present? ? maintainable.to_s : other_maintainable_location
  end

  def due_to_date=(val)
    if val =~ %r{\A(\d+)/(\d+)/(\d{4})\z}
      write_attribute(:due_to_date, Date.new($3.to_i, $1.to_i, $2.to_i))
    end
  end

  def pm_work_order?
    checklist_item_maintenance && checklist_item_maintenance.maintenance_record
  end

  def sub_category
    case maintainable_type
    when 'Maintenance::Room'
      checklist_item_name
    when 'Maintenance::PublicArea'
      maintainable.name
    when 'Maintenance::Equipment'
      maintainable.equipment_type.name
    end
  end

  def messages_count
    messages.count + (closed? && closing_comment.present? ? 1 : 0)
  end

  def material_total
    materials.map(&:cost).reduce(&:+)
  end

  private

  def update_closed_at
    if status_changed? && closed?
      self.closed_at = Time.now
      self.closed_by = updator
    end
  end

  def send_notification_and_mail_to_assignee
    if (assigned_to_id_changed? || priority_changed?) && assigned_to && priority=='h'
      Notification.assigned_work_order(self)
      begin
        MaintenanceWorkOrderMailer.work_order_notification_to_assignee(self).deliver!
      rescue => e
        Airbrake.notify(e)
        Rails.logger.error "Failed to send notification for work order - #{e.message}"
      end
      if assigned_to.phone_number.present?
        TWILIO.send_sms(
          assigned_to.phone_number,
          I18n.t(
            "maintenance.work_orders.sms.assigned",
            id: id,
            url: "#{maintenance_work_orders_url}?id=#{id}",
            assignee_name: assigned_to.name,
            location_and_checklist_name: [maintainable && maintainable.to_s || other_maintainable_location, checklist_item_name].join(', '),
            hotel_name: Property.current.name
          )
        )
      end
      true
    end
  end

  def create_wo_activity
    if created_at_changed?
      create_activity key: 'work_order.created', recipient: Property.current, owner: opened_by
    elsif status_changed?
      case status
        when 'open'
          create_activity key: 'work_order.reopened', recipient: Property.current, owner: updator
        when 'closed'
          create_activity key: 'work_order.closed', recipient: Property.current, owner: updator
        when 'working'
          create_activity key: 'work_order.status_working', recipient: Property.current, owner: updator
      end
    end
    true
  end

  def set_default_values
    self.status ||= STATUS_OPEN.to_s
    self.assigned_to_id ||= UNASSIGNED
    self.priority ||= 'm'
  end
end