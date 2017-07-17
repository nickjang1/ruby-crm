class Notification < ActiveRecord::Base

  belongs_to :user
  belongs_to :property

  scope :unread, -> { where.not read: true }
  scope :deleted, -> { where deleted: nil }

  default_scope { where(property_id: Property.current_id).order(created_at: :desc) }

  def self.purchase_order_fax_notification user_id, type, id, message
    notification             = Notification.new
    notification.user_id     = user_id
    notification.property_id = Property.current_id
    notification.model_id    = id
    notification.ntype       = type
    notification.message     = message

    notification.save
  end

  def self.purchase_request_approval user_ids, id, message
    user_ids.each do |user_id|
      notification             = Notification.new
      notification.user_id     = user_id
      notification.ntype       = 'request.approve'
      notification.model_id    = id
      notification.message     = message
      notification.property_id = Property.current_id

      notification.save
    end
  end

  def self.purchase_request_checked user_id, id, message, state
    notification             = Notification.new
    notification.user_id     = user_id
    notification.ntype       = "request.#{state}"
    notification.model_id    = id
    notification.message     = message
    notification.property_id = Property.current_id

    notification.save
  end
  
  def self.assigned_work_order(work_order)
    notification             = Notification.new
    notification.user_id     = work_order.assigned_to_id
    notification.ntype       = 'work_order.assigned'
    notification.model_id    = work_order.id
    notification.message     = "You have been assigned to new work order #{work_order.location_name}"
    notification.property_id = Property.current_id

    notification.save 
  end

end
