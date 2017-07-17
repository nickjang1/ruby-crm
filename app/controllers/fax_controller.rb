class FaxController < ApplicationController
  require 'json'
  include PusherHelper
  respond_to :json, :html
  # before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token

  def show
    po = PurchaseOrder.find(params[:id])
    respond_with({sent: po.sent_by_fax?}, location: po)
  end

  def create
    po = PurchaseOrder.find(params[:id])
    vendor_fax_number = po.vendor.fax

    if vendor_fax_number.present?
      FaxWorker.perform_async(vendor_fax_number, po.id, current_user.id)
      respond_with({result: :ok, polling_url: fax_path(purchase_order_id: params[:id])}, status: :created, location: po) do |format|
        format.html { redirect_to po, notice: I18n.t('controllers.fax.fax_being_processing') }
        format.json { render json: { message: I18n.t('controllers.fax.fax_being_processing') } }
      end
    else
      respond_with({result: :error}, status: :unprocessable_entity, location: nil) do |format|
        format.html { redirect_to po, alert: I18n.t('controllers.fax.vendor_has_no_fax') }
        format.json { render json: { message: I18n.t('controllers.fax.vendor_has_no_fax') }, status: :unprocessable_entity }
      end
    end
  end

  def update
    response = JSON.parse(params[:fax])
    po = PurchaseOrder.unscoped.where(fax_id: response['id']).first
    Property.current_id = po.property_id
    if response['status'] == 'success'
      po.update_attributes fax_last_message: 'Sent', fax_last_status: PurchaseOrder::FAX_SUCCESS
      po.sent!

      Notification.purchase_order_fax_notification po.last_user_id, 'fax.sent', po.id, I18n.t('controllers.fax.fax_sent_successfully')
      send_fax_event PurchaseOrder::FAX_SUCCESS, {message: I18n.t('controllers.fax.fax_sent'), po_number: po.number, to: po.last_user_id}
    elsif response['status'] == 'failure'
      po.update_attributes fax_last_message: response['error_code'], fax_last_status: PurchaseOrder::FAX_FAILED

      Notification.purchase_order_fax_notification 'fax.failed', 'fax.failed', po.last_user_id, I18n.t('controllers.fax.failed_to_send')
      send_fax_event PurchaseOrder::FAX_FAILED, {message: I18n.t('controllers.fax.failed_to_send'), po_number: po.number, to: po.last_user_id}
    end
    render nothing: true
  end
end
