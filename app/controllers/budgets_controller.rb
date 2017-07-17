class BudgetsController < ApplicationController
  
  before_action :authenticate_user!
  before_action :authorize

  respond_to :html, :json
  
  def index
    @first_half = (params[:first_half] || (Date.today.month - 1) / 6).to_i
    @year = (params[:year] || Date.today.year).to_i
    months = ((@first_half * 6)..(@first_half * 6 + 6)).to_a
    @budgets = Budget.where(year: @year, month: months).includes(:user)
    @total = @budgets.group(:month).sum(:amount)

    respond_to do |format|
      format.html { render :index }
      format.json { 
        render json: {
          year: @year, 
          first_half: @first_half, 
          budgets: @budgets.to_json(include: {user: {only: :name}})
        }
      }
    end
  end
  
  def create
    categories = params[:budget].delete(:categories).reject(&:blank?)
    categories = Category.pluck(:id) if categories.blank?
    amount = params[:budget].delete :amount
    @budgets = []
    Category.where(id: categories).each do |c|
      budget = c.budgets.where(params[:budget]).first || c.budgets.build(budget_params)
      budget.user = current_user
      budget.amount = amount
      budget.save!
      @budgets << budget
    end

    render json: {budgets: @budgets}
  end
  
  def edit
    @budget = Budget.find(params[:id])
    respond_with @budget
  end
  
  def update
    @budget = Budget.find(params[:id])
    @old_category_id = @budget.category_id
    @old_month = @budget.month
    if @budget.update_attributes(budget_params)
      render json: {budgets: [@budget], old_category_id: @old_category_id, old_month: @old_month}
    else
      render json: {error: "Failed to update budget."}, status: 422
    end
  end
  
  def destroy
    @budget = Budget.find(params[:id])
    @category_id = @budget.category_id
    @month = @budget.month
    if @budget.destroy
      render json: {category_id: @category_id, month: @month}
    else
      render json: {}, status: 422
    end
  end
  
  private
  def authorize
    authorize! params[:action].to_sym, Budget
  end

  def budget_params
    params.require(:budget).permit(:amount, :year, :month)
  end
  
end