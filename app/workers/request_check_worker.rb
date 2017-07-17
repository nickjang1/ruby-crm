class RequestCheckWorker
  include Sidekiq::Worker
  include ApplicationHelper
  include PusherHelper

  sidekiq_options queue: "high", retry: 0

  def perform(request_id, user_id, state, name)
    @request = PurchaseRequest.unscoped.find request_id
    Property.current_id = @request.property_id

    Mailer.send_request_checked(request_id, state, user_id).deliver

    Notification.purchase_request_checked(
      user_id, 
      @request.id, 
      I18n.t(
        "purchase_requests.purchase_request.approval.#{state}", 
        request_number: @request.number, 
        name: name
      ) + " Click here to review.", 
      state
    )
    send_request_approval_checked_event({message: "Your Request (#{@request.number}) has been #{state}.", to: user_id, state: state})
  end

end
