class Maintenance::RecordsController < Maintenance::BaseController
  include SentientController
  before_filter :get_maintenance_record, only: [:show, :update, :destroy, :complete_inspection, :cancel_inspection]

  def index
    @status = params[:status] || Maintenance::MaintenanceRecord::STATUS_IN_PROGRESS
    @type = params[:type] || 'Maintenance::Room'
    @records = Maintenance::MaintenanceRecord.by_type(@type).by_status(@status)
    render json: @records.to_json, status: 200
  end

  def update
    if @record.update_attributes record_parameters
      fixed_count = @record.checklist_item_maintenances.fixed.count
      work_order_count = @record.checklist_item_maintenances.issues.count
      @info = []
      @info.push t('.maintenance_fixed_info', count: fixed_count) if fixed_count > 0
      @info.push t('.maintenance_work_order_info', count: work_order_count) if work_order_count > 0
      redirect_to after_updating_record_path, notice: set_notice_after_updating
    else
      redirect_to after_updating_record_path, alert: 'Failed to update maintenance record'
    end
  end

  def complete_inspection
    @record.update_attributes status: Maintenance::MaintenanceRecord::STATUS_COMPLETED, inspected_by_id: current_user.id, inspected_on: Time.current
    redirect_to after_inspect_record_path
  end

  def cancel_inspection
    @record.cancel_inspection
    redirect_to after_inspect_record_path
  end

  def destroy
    if @record.destroy
      redirect_to after_destroy_path, notice: 'All maintenance progress is removed.'
    else
      redirect_to after_destroy_path, alert: 'Failed to remove maintenance record.'
    end
  end

  private
  
  def after_updating_record_path
    if @record.maintainable_type == 'Maintenance::Room'
      maintenance_rooms_path
    elsif @record.maintainable_type == 'Maintenance::PublicArea'
      maintenance_public_areas_path
    elsif @record.maintainable_type == 'Maintenance::Equipment'
      maintenance_equipments_path
    end
  end

  def after_inspect_record_path
    @record.maintainable_type == 'Maintenance::Room' ? inspection_maintenance_rooms_path : inspection_maintenance_public_areas_path
  end
  
  def set_notice_after_updating
    if @record.maintainable_type == 'Maintenance::Room'
      t('.maintenance_completed', room_number: @record.maintainable.room_number) + @info.to_sentence
    elsif @record.maintainable_type == 'Maintenance::PublicArea'
      t('.public_area_maintenance_completed', public_area: @record.maintainable.name) + @info.to_sentence
    elsif @record.maintainable_type == 'Maintenance::Equipment'
      t('.equipment_maintenance_completed', equipment: @record.maintainable.name) + @info.to_sentence
    end
  end

  def after_destroy_path
    if @record.maintainable_type == 'Maintenance::Room'
      maintenance_rooms_path
    elsif @record.maintainable_type == 'Maintenance::PublicArea'
      maintenance_public_areas_path
    elsif @record.maintainable_type == 'Maintenance::Equipment'
      maintenance_equipments_path
    end
  end
  
  def get_maintenance_record
    @record = Maintenance::MaintenanceRecord.find params[:id]
  end

  def record_parameters
    params.require(:maintenance_maintenance_record).permit(:status, :user_id, :completed_on, :completed_by)
  end

end
