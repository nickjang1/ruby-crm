class Corporate::PurchaseRequestsController < ApplicationController
  add_breadcrumb I18n.t("purchase_requests.index.name"), :purchase_requests_path
  before_filter :authenticate_user!
  respond_to :html, :json

  def edit
    @property = current_corporate.properties.find params[:property_id]
    @property.switch!
    @purchase_request = PurchaseRequest.find params[:id]

    add_breadcrumb I18n.t("purchase_requests.edit.states.#{ @purchase_request.state }")
    add_breadcrumb I18n.t("purchase_requests.edit.request_number", request_number: @purchase_request.number)
    
    @item_requests = @purchase_request.item_requests
    @item_requests_grouped = @item_requests.group_by { |ir| ir.order_number } if @purchase_request.ordered?

    Property.current_id = nil

    respond_with @purchase_request do |format|
      format.html {render 'completed'}
    end
  end

  def update
    @property = current_corporate.properties.find params[:property_id]
    @property.switch!
    @purchase_request = PurchaseRequest.find params[:id]
    @item_requests = @purchase_request.item_requests
    original_id    = @purchase_request.user_id

    if @purchase_request.update_attributes(purchase_request_params)
      @purchase_request.send(params[:commit])
      approval = @purchase_request.approval_request @property, current_user if @purchase_request.state == 'completed'
      
      @purchase_request.create_orders_on_approval!(current_user, @property) if params[:commit] == 'approve'
      @purchase_request.approve_reject params[:commit], original_id, current_user
      flash[ params[:commit] == 'reject' ? :error : :notice ] = I18n.t("purchase_requests.finish_step_message.#{ params[:commit] }", req_number: @purchase_request.number, orders_count: @purchase_request.purchase_orders.count)
      Property.current_id = nil
      redirect_to :corporate_root and return
    else
      Property.current_id = nil
      render @purchase_request.state
    end
  end
  
  private

  def purchase_request_params
    params.require(:purchase_request).permit :rejection_reason
  end

end
