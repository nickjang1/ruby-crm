class Alarm < ActiveRecord::Base
  belongs_to :user
  belongs_to :checked_by, class_name: 'User', foreign_key: 'checked_by'
  belongs_to :property

  validates :body, :presence => true
  validates :user, :presence => true

  scope :alarm_on, -> (date) { where(alarm_at: date.beginning_of_day..date.end_of_day).order(:alarm_at) }

  def alarm_at=(time)
    write_attribute(:alarm_at, DateTime.parse(time).change(offset: '00:00'))
  end

  def as_json(options={})
    {
        id: id,
        body: body,
        alarm_at: alarm_at.utc.strftime('%I:%M %p'),
        created_at: created_at.strftime('%b %d, %I:%M %p'),
        user_name: user.name,
        user_avatar: user.avatar.thumb.url,
        is_checked: checked_on.present?,
        checked_on: checked_on ? checked_on.strftime('%b %d, %I:%M %p') : nil,
        checked_by: checked_on ? checked_by.try(:name) : nil
    }
  end
end
