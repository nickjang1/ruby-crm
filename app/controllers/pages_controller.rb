class PagesController < ApplicationController
  include PermissionsHelper
  respond_to :html
  
  before_filter :authenticate_user!, except: :home
  before_filter :load_requests_orders_and_lists, only: [:dashboard]
  
  def dashboard
    @pos = PurchaseOrderDecorator.decorate_collection @pos
    @requests_and_orders = @prs + @pos
    @requests_and_orders = @requests_and_orders.sort_by {|ro| ro.state }
  end

  def setup
  end

  def spend_vs_budgets_data
    time_from = params[:range] == 'year' ? Time.now.beginning_of_year : Time.now.beginning_of_month
    @budget_spend_data = {
      data: { budget:[], spend: []},
      categories: []
    }
    Category.includes(:items).load.each do |category|
      item_ids = category.item_ids
      next if item_ids.count == 0
      spend  = PurchaseReceipt.include_items(item_ids).where(created_at: time_from..Time.now).map{ |receipt| receipt.total(item_ids) }.reduce(&:+).to_f
      budget = category.budgets.where(created_at: Time.now.beginning_of_year..Time.now).sum(:amount).to_f
      next if !spend && !budget
      @budget_spend_data[:categories] << category.name
      @budget_spend_data[:data][:budget] << budget
      @budget_spend_data[:data][:spend] << spend
    end
    render json: @budget_spend_data.to_json
  end

  def home
    if user_signed_in?
      if current_user.corporate? && Property.current.nil?
        redirect_to :corporate_root
      elsif current_user.permission_attributes.level2.access_attributes.count == 1
        redirect_to priority_path
      elsif policy(:access).maintenance?
        redirect_to :maintenance_root
      else
        redirect_to dashboard_path
      end
    else
      render layout: false
    end
  end

  private

  def load_requests_orders_and_lists
    @prs = PurchaseRequest.order(updated_at: :asc).without_inventory_finished.where.not(state: 'ordered')
    @pos = PurchaseOrder.order(updated_at: :asc).where(closed_at: nil)

    if current_user.current_property_role == Role.manager
      @prs = @prs.where(user: current_user)
      @pos = @pos.where("user_id=? OR purchase_request_id IN (?)", current_user.id, current_user.purchase_request_ids)
      @lists = List.where(user: current_user).top_six_for_user(current_user)
    else
      @lists = List.top_six_for_user(current_user)
    end
  end
end
