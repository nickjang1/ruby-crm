class PurchaseRequestsController < ApplicationController
  add_breadcrumb I18n.t("purchase_requests.index.name"), :purchase_requests_path
  before_filter :authenticate_user!
  load_and_authorize_resource except: [:index, :edit, :create, :add_message, :messages]
  before_action :load_requests, only: [:index]
  respond_to :html, :json

  def index
    authorize! :index, PurchaseRequest
    respond_with @purchase_requests
  end

  def show
  end

  def new
    authorize! :create, PurchaseRequest
    @q = Item.search_tree(params[:q])
    @items = @q.result(distinct: true)

    (params[:q] && params[:q][:lists_id_eq_any] || [] ).each do |list_id|
      UserListUsage.create(user_id: current_user.id, list_id: list_id)
    end

    @purchase_request = PurchaseRequest.new
    @items.each do |item|
      @purchase_request.item_requests.build(item: item)
    end

    respond_with @purchase_request do |format|
      format.html {render 'inventory'}
    end
  end

  def create
    authorize! :create, PurchaseRequest
    @purchase_request = PurchaseRequest.new(purchase_request_params)
    @purchase_request.property = current_property
    @purchase_request.user = current_user
    @purchase_request.save
    @purchase_request.send(params[:commit].gsub(/&/, 'and').parameterize('_'))

    @purchase_request.messages << Message.where(id: params[:message_ids].split(',')) unless params[:message_ids].nil?

    flash[:notice] = 'Success' if params[:commit] == 'commit'

    if params[:commit] == 'finish'
      flash[:notice] = I18n.t("purchase_requests.finish_step_message.finish", req_number: @purchase_request.number, orders_count: @purchase_request.purchase_orders.count)
      redirect_to :purchase_requests and return
    end

    unless params[:print].blank?
      redirect_to inventory_print_purchase_request_path(@purchase_request)
    else
      redirect_to edit_purchase_request_path(@purchase_request)
    end
  end

  def edit
    @purchase_request = PurchaseRequest.find_by_id(params[:id])
    authorize! :edit, @purchase_request
    add_breadcrumb I18n.t("purchase_requests.edit.states.#{ @purchase_request.state }")
    add_breadcrumb I18n.t("purchase_requests.edit.request_number", request_number: @purchase_request.number)
    @item_requests = @purchase_request.item_requests
    @item_requests_grouped = @item_requests.group_by { |ir| ir.order_number } if @purchase_request.ordered?

    respond_with @purchase_request do |format|
      format.html {render @purchase_request.state}
      format.pdf do
        kit = PDFKit.new(render_to_string action: :inventory, layout: false, formats: :html)
        kit.stylesheets << Rails.root.join('public', 'stylesheets', 'print.css')
        send_data kit.to_pdf, type: 'application/pdf', filename: "inventory_pr_#{@purchase_request.id}.pdf"
      end
    end
  end

  def update
    @item_requests = @purchase_request.item_requests

    commit = params[:commit]

    original_id = @purchase_request.user_id
    unless params[:print].blank?
      redirect_to inventory_print_purchase_request_path(@purchase_request) and return
    end

    @purchase_request.assign_attributes(purchase_request_params)
    item_requests_changed = @purchase_request.quantities_changed?
    if @purchase_request.save
      @purchase_request.send(commit.gsub(/&/, 'and').parameterize('_'))
      approval = @purchase_request.approval_request current_property, current_user if @purchase_request.state == 'completed'

      if %w(reject approve commit finish).index(commit)
        @purchase_request.create_orders_on_approval!(current_user, current_property) if commit == 'approve'
        Notification.purchase_request_approval([@purchase_request.user_id], @purchase_request.id,
          I18n.t("purchase_requests.completed_with_edits.#{ commit }", req_number: @purchase_request.number)) if %w(reject approve).index(commit) && item_requests_changed

        @purchase_request.approve_reject commit, original_id, current_user
        flash[ commit == 'reject' ? :error : :notice ] = I18n.t("purchase_requests.finish_step_message.#{ commit }", req_number: @purchase_request.number, orders_count: @purchase_request.purchase_orders.count)
        redirect_to :purchase_requests and return
      end

      redirect_to [:edit, @purchase_request]
    else
      render @purchase_request.state
    end
  end

  def inventory_print
    @item_requests = @purchase_request.item_requests

    respond_with @purchase_request do |format|
      format.html {render layout: 'print'}
    end
  end
  
  private

  def load_requests
    @showing_closed = params[:scope] == 'closed'
    if current_user.current_property_role == Role.corporate
      @purchase_requests = PurchaseRequest.where(state: 'completed').without_inventory_finished.order(updated_at: :desc)
        .select{|pr| pr.total_price > current_property.highest_gm_approval_limit }
    else
      @purchase_requests = PurchaseRequest.accessible_by(current_ability).without_inventory_finished.order(updated_at: :desc)
      @purchase_requests = @showing_closed ? @purchase_requests.with_state(:ordered) : @purchase_requests.without_state(:ordered)
    end
  end

  def purchase_request_params
    if params.include? :purchase_request
      if params[:purchase_request][:item_requests_attributes]
        params[:purchase_request][:item_requests_attributes].each do |key, ir|
          if ir[:count].is_a? Array
            sum = ir[:count].map(&:to_i).reduce(&:+)
            ir[:count] = sum
          end
        end
      end

      params.require(:purchase_request).permit :rejection_reason, item_requests_attributes: [:id, :item_id, :quantity, :count, :skip_inventory, :_destroy]
    else
      params.to_hash.delete :utf8
    end
  end

end
