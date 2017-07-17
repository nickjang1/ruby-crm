class FaxWorker
  include Sidekiq::Worker
  include ApplicationHelper
  include PusherHelper

  sidekiq_options queue: "high", retry: 0

  def perform(number, po_id, current_user_id)
    po = PurchaseOrder.unscoped.find po_id
    Property.current_id = po.property.id
    ac = ActionController::Base.new()
    string_data = ac.render_to_string(layout: 'layouts/pdf.html.haml',
                                      template: 'purchase_orders/pdf.html.slim',
                                      formats: :html,
                                      locals: {:@purchase_order => po})

    response = Phaxio.send_fax to: number, 
                    filename: 'purchase_order.pdf', 
                    string_data: string_data, 
                    string_data_type: :html, 
                    callback_url: "http://#{Settings.external_host}/phaxio"

    if response['success']
      po.update_attributes fax_id: response['faxId'], fax_last_message: response['message'], last_user_id: current_user_id, fax_last_status: PurchaseOrder::FAX_SENDING
      send_fax_event PurchaseOrder::FAX_SENDING, {message: response['message'], po_number: po.number, to: current_user_id}
    else
      po.update_attributes fax_id: response['faxId'], fax_last_message: response['message'], last_user_id: current_user_id, fax_last_status: PurchaseOrder::FAX_FAILED
      send_fax_event PurchaseOrder::FAX_FAILED, {message: response['message'], po_number: po.number, to: current_user_id}
    end
  end

end
