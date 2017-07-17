class Maintenance::WorkOrdersController < Maintenance::BaseController
  before_filter :authorize_work_order
  around_filter :action_with_property, only: [:new, :create, :edit, :update, :trends]
  include SentientController

  def new
    @work_order = Maintenance::WorkOrder.new(status: :open, priority: :m, assigned_to_id: Maintenance::WorkOrder::UNASSIGNED)
    @work_order.build_checklist_item_maintenance
    2.times { @work_order.attachments.build }
    render layout: false
  end

  def create
    @work_order = Maintenance::WorkOrder.new(permitted_attributes)
    authorize @work_order

    @work_order.opened_at = Time.zone.now
    @work_order.opened_by = current_user
    @work_order.save
    render partial: 'work_order', locals: { work_order: @work_order }
  end

  def edit
    @work_order = Maintenance::WorkOrder.find params[:id]
    # authorize @work_order
    (2 - @work_order.attachments.count).times { @work_order.attachments.build }
    render layout: false
  end

  def update
    @work_order = Maintenance::WorkOrder.find params[:id]
    authorize @work_order
    @work_order.update(permitted_attributes)
    if !scoped_work_orders.map(&:id).include?(@work_order.id)
      head 200
    else
      if request.format.json?
        render json: @work_order
      else
        render partial: 'work_order', locals: { work_order: @work_order }
      end
    end
  end

  def destroy
    @work_order = Maintenance::WorkOrder.find params[:id]
    authorize @work_order
    if @work_order.destroy
      render json: @work_order.id
    else
      render json: {error: 'Failed to delete Equipment Type'}, status: 422
    end
  end

  def index
    authorize Maintenance::WorkOrder
    @filter = params[:filter] || {status: 'active'}
    @current_properties = current_properties
    @users = [{id: current_user.id, name: 'My WOs'}] + [{id: Maintenance::WorkOrder::UNASSIGNED, name: Maintenance::WorkOrder::UNASSIGNED_NAME}] +
      [{id: Maintenance::WorkOrder::THIRD_PARTY, name: Maintenance::WorkOrder::THIRD_PARTY_NAME}] +
      scoped_users.map { |u| {id: u.id, name: u.name_with_status} }
    @closed_users = @users.select { |u| !Maintenance::WorkOrder::EXTRA_IDS.include?(u[:id]) }

    respond_to do |format|
      format.html
      format.js do
        @work_orders = scoped_work_orders(@filter)
      end
    end
  end

  private

  def permitted_attributes
    @work_order ||= Maintenance::WorkOrder.new
    params.require(:maintenance_work_order).permit(policy(@work_order).permitted_attributes)
  end

  def current_properties
    current_user.corporate? ? current_user.all_properties : [Property.current]
  end

  def scoped_work_orders(filter = {})
    @work_orders = []
    @includes ||= [
      {checklist_item_maintenance: [:maintenance_checklist_item, :maintenance_record]},
      :opened_by, :assigned_to,
      {maintainable: [:equipment_type]}
    ]
    ActiveRecord::lax_includes do
      if current_user.corporate?
        current_properties.each do |p|
          p.run_block_with_no_property do
            @work_orders += Pundit.policy_scope!(current_user, Maintenance::WorkOrder)
                              .by_filter(filter)
                              .order(created_at: :desc)
                              .includes(@includes).to_a
          end
        end
      else
        @work_orders = policy_scope(Maintenance::WorkOrder)
                         .by_filter(filter)
                         .order(created_at: :desc)
                         .includes(@includes).to_a
      end
    end
    @work_orders
  end

  def scoped_users
    users = []
    if current_user.corporate?
      current_user.all_properties.find_each do |p|
        p.run_block_with_no_property do
          users += User.where(id: p.user_roles.with_deleted.where.not(user_id: current_user.id).pluck(:user_id)).to_a
        end
      end
    else
      users = User.where(id: Property.current.user_roles.with_deleted.where.not(user_id: current_user.id).pluck(:user_id)).to_a
    end
    users.uniq.sort_by &:name
  end
end
