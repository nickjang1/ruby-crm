class PurchaseReceiptsController < ApplicationController
  add_breadcrumb I18n.t("controllers.purchase_receipts.orders"), :purchase_orders_path

  before_filter :authenticate_user!
  respond_to :html

  def new
    @purchase_order = PurchaseOrder.find(params[:purchase_order_id])
    @purchase_receipt = PurchaseReceipt.new(purchase_order: @purchase_order)
    authorize! :new, @purchase_receipt
    add_breadcrumb t("controllers.purchase_receipts.order", number: @purchase_order.number), purchase_order_path(@purchase_order) 
    add_breadcrumb t("controllers.purchase_receipts.receiving", ordinal: ordinal)
    respond_with @purchase_receipt
  end

  def create
    @purchase_receipt = PurchaseReceipt.new(purchase_receipt_params)
    authorize! :create, @purchase_receipt
    @purchase_receipt.property = current_property
    @purchase_receipt.user = current_user
    @purchase_receipt.save

    update_item_price
      
    if @purchase_receipt.purchase_order.complete?
      @purchase_receipt.purchase_order.closed!
    else
      @purchase_receipt.purchase_order.partially_received!
    end

    redirect_to purchase_orders_path, notice: t("controllers.purchase_receipts.order_received", number: @purchase_receipt.purchase_order.number)
  end

  private

  def purchase_receipt_params
    params.require(:purchase_receipt).permit :purchase_order_id, :freight_shipping, item_receipts_attributes: [:id, :item_id, :item_order_id, :quantity, :price]
  end

  def ordinal
    @purchase_receipt.is_first? ? '' : current_receiving_number.ordinalize
  end

  def current_receiving_number
    @purchase_order.purchase_receipts.count + 1
  end

  def update_item_price
    @purchase_receipt.item_receipts.each do |ir|
      vendor_item = ir.item.vendor_items.find_by_vendor_id(@purchase_receipt.purchase_order.vendor.id)
      unless vendor_item.price == ir.price
        vendor_item.price = ir.price
        vendor_item.save
      end
    end
  end
end
