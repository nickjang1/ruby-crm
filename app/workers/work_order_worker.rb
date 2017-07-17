class WorkOrderWorker
  include Sidekiq::Worker
  include ApplicationHelper
  include PusherHelper

  sidekiq_options queue: "high", retry: 0

  def perform(work_order_id)
    work_order = Maintenance::WorkOrder.find work_order_id
    #send_fax_event PurchaseOrder::FAX_SENDING, {message: response['message'], po_number: po.number, to: current_user_id}
    send_work_order_notification 'notification.send',{message: 'your are assigned to work order',to: work_order.assigned_to_id}
  end

end
