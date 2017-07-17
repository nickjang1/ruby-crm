class RequestApprovalWorker
  include Sidekiq::Worker
  include ApplicationHelper
  include PusherHelper

  sidekiq_options queue: "high", retry: 0

  def perform(emails, request_id, approver_ids)
    @request = PurchaseRequest.unscoped.find request_id
    Property.current_id = @request.property_id
    Mailer.send_approval_request(emails, request_id)

    send_request_approval_sent_event(
      message: I18n.t('purchase_requests.purchase_request.approval.approval_request_sent', request_number: @request.number),
      to: @request.user_id
    )

    Notification.purchase_request_approval(
      approver_ids, 
      @request.id, 
      I18n.t('purchase_requests.purchase_request.approval.request', request_number: @request.number)
    )
    send_request_approve_received_event(
      message: I18n.t('purchase_requests.purchase_request.approval.approval_request_received', request_number: @request.number),
      to: approver_ids
    )
  end

end
