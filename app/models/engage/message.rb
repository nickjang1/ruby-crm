class Engage::Message < ActiveRecord::Base
  include SentientUser

  self.table_name = "engage_messages"

  acts_as_votable
  include PublicActivity::Common

  belongs_to :property
  belongs_to :work_order, class_name: 'Maintenance::WorkOrder', foreign_key: :work_order_id
  belongs_to :room, class_name: 'Maintenance::Room', foreign_key: :room_number, primary_key: :room_number
  belongs_to :created_by, class_name: 'User', foreign_key: :created_by_id
  belongs_to :completed_by, class_name: 'User', foreign_key: :completed_by_id
  belongs_to :parent, class_name: 'Engage::Message', foreign_key: :parent_id, inverse_of: :replies
  has_many :replies, class_name: 'Engage::Message', foreign_key: :parent_id

  validates :property, associated: true
  validates :body, :created_by, presence: true

  attr_encrypted :body
  after_create :create_comment_activity

  default_scope { where(property_id: Property.current_id) }
  scope :threads, -> { where(parent_id: nil) }
  scope :occurred_on, -> (date) {
    where(
      "(created_at >= ? AND created_at <= ?) OR (follow_up_start IS NOT NULL AND follow_up_end IS NOT NULL AND follow_up_start <= ? AND follow_up_end >= ?)",
      date.beginning_of_day, date.end_of_day, date, date
    ).order(created_at: :asc)
  }
  scope :follow_ups, -> (date) { where("follow_up_start <= ? AND follow_up_end >= ?", date, date) }
  scope :broadcast, -> { where("broadcast_start <= ? AND broadcast_end >= ?", Date.today, Date.today) }

  def self.broadcast_messages
    Engage::Message.broadcast.includes(:created_by).map do |m|
      {
        id: m.id,
        body: m.body,
        created_at: I18n.l(m.created_at, format: :engage_time),
        created_at_date: I18n.l(m.created_at, format: :mini),
        created_by: m.created_by.name,
        created_by_avatar: m.created_by.avatar.thumb.url,
      }
    end
  end

  def like=(value)
    if value == 'true'
      self.liked_by User.current
    end
  end

  def complete=(value)
    if value == 'true'
      self.complete!
    else
      self.uncomplete!
    end
  end

  def completed?
    completed_at.present?
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

  def follow_up?
    follow_up_start.present? && follow_up_end.present?
  end

  def follow_up_show?(date)
    follow_up? && follow_up_start <= date && follow_up_end >= date
  end

  def broadcast?
    broadcast_start.present? && broadcast_end.present?
  end

  def broadcast_show?
    broadcast? && broadcast_start <= Time.current && broadcast_end >= Time.current
  end

  def show_up?(date)
    date.beginning_of_day <= created_at && created_at <= date.end_of_day
  end

  def follow_up_range
    if follow_up?
      follow_up_start == follow_up_end ? I18n.l(follow_up_start, format: :mini) : "#{I18n.l(follow_up_start, format: :mini)} - #{I18n.l(follow_up_end, format: :mini)}"
    end
  end

  def broadcast_range
    if broadcast?
      broadcast_start == broadcast_end ? I18n.l(broadcast_start, format: :mini) : "#{I18n.l(broadcast_start, format: :mini)} - #{I18n.l(broadcast_end, format: :mini)}"
    end
  end

  def create_comment_activity
    create_activity key: "comment.created", recipient: Property.current, owner: created_by
  end

  def as_json(options = {})
    {
      id: id,
      title: title,
      body: body,
      room_number: "#{room_number}",
      wo_id: work_order.try(:id),
      created_at: I18n.l(created_at, format: :engage_time),
      created_at_date: I18n.l(created_at, format: :mini),
      created_by: created_by.name,
      created_by_avatar: created_by.avatar.thumb.url,
      completed_at: !!completed_at ? I18n.l(completed_at, format: :date_and_am_pm) : nil,
      completed_by: completed_by.try(:name),
      follow_up_show: follow_up_show?(options[:date]),
      follow_up_range: follow_up_range,
      follow_up_start: follow_up_start,
      follow_up_end: follow_up_end,
      broadcast_show: broadcast_show?,
      broadcast_range: broadcast_range,
      broadcast_start: broadcast_start,
      broadcast_end: broadcast_end,
      show_up: show_up?(options[:date]),
      liked: options[:user].liked?(self),
      likes_count: get_likes.count,
      likes: get_likes.map { |v| {name: v.voter.name, avatar: v.voter.avatar.thumb.url} },
      parent_id: parent_id,
      work_order_id: work_order_id,
      replies: replies.order(created_at: :desc).map { |r| {body: r.body, created_by: r.created_by.name, created_by_avatar: r.created_by.avatar.thumb.url, created_at: I18n.l(r.created_at, format: :engage_time), created_at_date: I18n.l(r.created_at, format: :mini)} }
    }
  end
end
