class EmailController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def create
    @purchase_order = PurchaseOrder.find(params[:id]).decorate
    @purchase_order.send_email
    @purchase_order.sent!

    flash[:notice] = I18n.t('controllers.email.email_sent')
    if params[:redirect_to]
      redirect_to params[:redirect_to]
    else
      redirect_to purchase_orders_path
    end
  end
end
