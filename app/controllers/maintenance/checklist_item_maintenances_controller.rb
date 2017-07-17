class Maintenance::ChecklistItemMaintenancesController < Maintenance::BaseController

  before_filter :get_maintainable, only: [:index, :create, :inspect, :equipment]

  def index
    render json: @maintainable.maintenance_records.find(params[:record_id]).to_json(
         include: { checklist_item_maintenances: { include: [:work_order, :inspection_work_order] } }
      ), status: 200
  end

  def equipment
    render json: @maintainable.maintenance_records.where(id: params[:record_id]).first.to_json(
               include: { checklist_item_maintenances: { include: [:work_order, :inspection_work_order] } }
           ), status: 200
  end

  def create
    if !policy(Maintenance::ChecklistItemMaintenance).single_click_pm? && params[:checklist_item_ids] && params[:checklist_item_ids].count > 1
      render json: {message: 'You are not authroized to do single click PM'}, status: 401 and return
    end
    if params[:record_id]
      @record = @maintainable.maintenance_records.find params[:record_id]
    else
      @record = @maintainable.maintenance_records.for_cycle(params[:cycle_id])
    end
    checklist_item_ids = (params[:checklist_item_ids] || []).map(&:to_i) - @record.checklist_item_maintenances.pluck(:maintenance_checklist_item_id)
    item_maintenance_ids = []
    checklist_item_ids.each do |item_id|
      checklist_item_maintenance = @record.checklist_item_maintenances.find_or_initialize_by(maintenance_checklist_item_id: item_id)

      if params[:status] == Maintenance::ChecklistItemMaintenance::STATUS_ISSUES.to_s
        checklist_item_maintenance.update_attributes status: params[:status]

        work_order = Maintenance::WorkOrder.new(work_order_params)
        work_order.checklist_item_maintenance = checklist_item_maintenance
        work_order.opened_by = current_user
        work_order.maintainable = @maintainable
        work_order.opened_at = Time.current
        work_order.status = Maintenance::WorkOrder::STATUS_OPEN
        work_order.assigned_to_id = current_user.wo_assignable_id
        work_order.priority = 'l'
        work_order.save
      else
        checklist_item_maintenance.update_attributes(status: params[:status], comment: params[:comment])
      end
      item_maintenance_ids << checklist_item_maintenance.id
    end

    @checklist_item_maintenances = @record.checklist_item_maintenances.where(id: item_maintenance_ids)
    render json: @checklist_item_maintenances.to_json(include: :work_order), status: 200
  end

  def inspect
    @checklist_item_maintenance = Maintenance::ChecklistItemMaintenance.find params[:id]
    @inspection_detail = @checklist_item_maintenance.build_inspection_detail
    @work_order = @inspection_detail.build_work_order
    @work_order.maintainable = @maintainable
    @work_order.description = params[:comment]
    @work_order.opened_by = current_user
    @work_order.opened_at = Time.current
    @work_order.status = Maintenance::WorkOrder::STATUS_OPEN
    @work_order.priority = 'l'
    @work_order.checklist_item_maintenance = @checklist_item_maintenance
    completed_by = @checklist_item_maintenance.maintenance_record.completed_by
    @work_order.assigned_to_id = (completed_by && completed_by.wo_assignable_id) || Maintenance::WorkOrder::UNASSIGNED

    @inspection_detail.save

    render json: @inspection_detail.to_json(include: :work_order), status: 200
  end

  def cancel_inspect
    @checklist_item_maintenance = Maintenance::ChecklistItemMaintenance.find params[:id]
    @inspection_work_order = @checklist_item_maintenance.inspection_work_order
    @inspection_work_order.destroy

    render json: @checklist_item_maintenance.id, status: 200
  end

  def destroy
    @checklist_item_maintenance = Maintenance::ChecklistItemMaintenance.find params[:id]
    @checklist_item_maintenance.destroy
    render json: params[:id], status: 200
  end

  private

  def get_maintainable
    @maintainable = params[:maintainable_type].classify.constantize.find(params[:maintainable_id])
  end

  def work_order_params
    params.require(:maintenance_work_order).permit(
      :status, :description, :priority, :assigned_to_id, :maintainable_id, :maintainable_type, :other_maintainable_location, :due_to_date,
      attachments_attributes: [:id, :file, :_destroy ]
    )
  end

end
