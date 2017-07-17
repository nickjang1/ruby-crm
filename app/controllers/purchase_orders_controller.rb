require 'active_support/core_ext/hash/deep_merge'

class PurchaseOrdersController < ApplicationController
  add_breadcrumb I18n.t("purchase_orders.index.name"), :purchase_orders_path
  before_action :authenticate_user!, unless: :pdf_order?
  load_and_authorize_resource except: [:index]
  respond_to :html, :pdf

  def pdf_order?
    request.format.pdf? && params[:action] == 'show'
  end

  def index
    authorize! :index, PurchaseOrder
    @purchase_orders = if current_user.current_property_role == Role.manager
      PurchaseOrder.where("user_id=? OR purchase_request_id IN (?)", current_user.id, current_user.purchase_request_ids)
    else
      PurchaseOrder.accessible_by(current_ability)
    end
    @purchase_orders = @purchase_orders.order(created_at: :desc)
    @showing_closed  = params[:scope] == 'closed' 
    @purchase_orders = @showing_closed ? @purchase_orders.closed : @purchase_orders.not_closed

    @purchase_orders = PurchaseOrderDecorator.decorate_collection( @purchase_orders )

    respond_with @purchase_orders
  end

  def show
    @purchase_order = @purchase_order.decorate
    @emails = [@purchase_order.vendor.email, @purchase_order.purchase_request.user.email, current_user.email].uniq.reject(&:blank?) rescue []
    @item_receipts_per_item = @purchase_order.purchase_receipts.map(&:item_receipts).flatten.group_by(&:item)
    @purchase_request = @purchase_order.purchase_request
    @item_orders = @purchase_order.item_orders

    respond_to do |format|
      format.html
      format.pdf do
        pdf = WickedPdf.new.pdf_from_string(
                render_to_string('purchase_orders/pdf.html.slim', :layout => 'layouts/pdf.html.haml'),
              )
        send_data pdf, type: 'application/pdf', filename: "purchase_order_#{@purchase_order.id}.pdf", disposition: params[:disposition] || 'attachment'
      end
    end
  end

  def print
    @purchase_order = PurchaseOrder.find(params[:id]).decorate
    @purchase_request = @purchase_order.purchase_request

    render layout: 'print'
  end

  def update
    @purchase_order.update_attributes(purchase_order_params)
    redirect_to purchase_orders_path
  end

  def destroy # not really
    @purchase_order.close!
    redirect_to purchase_orders_path
  end

  private

  def purchase_order_params
    params.require(:purchase_order).permit :id, :sent, purchase_receipts_attributes: [:id, item_receipts_attributes: [:id, :item_id, :item_order_id, :quantity, :price]]
  end
end
