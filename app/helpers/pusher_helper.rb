module PusherHelper

  FAX_CHANNEL = 'fax_channel'
  REQUEST_CHANNEL = 'request_channel'
  WORK_ORDER_CHANNEL = 'work_order_channel'

  def add_env_info data
    if data[:to].is_a? Array
      to_array = data[:to].map { |to| Rails.env + '_' + to.to_s }
      data[:to] = to_array
    else
      data[:to] = Rails.env + '_' + data[:to].to_s
    end
    data
  end

  def send_fax_event event, data
    Pusher[FAX_CHANNEL].trigger event, add_env_info(data)
  end

  def send_request_approval_sent_event data
    Pusher[REQUEST_CHANNEL].trigger 'request.approve', add_env_info(data)
  end

  def send_request_approve_received_event data
    Pusher[REQUEST_CHANNEL].trigger 'request.approve.received', add_env_info(data)
  end

  def send_request_approval_checked_event data
    Pusher[REQUEST_CHANNEL].trigger 'request.checked', add_env_info(data)
  end
  
  def send_work_order_notification event,data
    Pusher[WORK_ORDER_CHANNEL].trigger event, add_env_info(data)
  end

end