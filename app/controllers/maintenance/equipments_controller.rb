class Maintenance::EquipmentsController < Maintenance::BaseController
  before_filter :get_equipment_type, only: [:create, :update, :destroy]
  add_breadcrumb I18n.t('controllers.maintenance.equipments.index'), :maintenance_equipments_path

  def index
    authorize :access, :pm?
    respond_to do |format|
      format.html
      format.json do
        @equipment_types = Maintenance::EquipmentType.active.includes(:active_equipments, :checklist_groups)
        render json: @equipment_types.to_json(include: [:active_equipments, :checklist_groups])
      end
    end
  end

  def show
    @equipment = Maintenance::Equipment.find params[:id]
    add_breadcrumb I18n.t('controllers.maintenance.equipments.show', name: @equipment.name)
    @group = Maintenance::EquipmentChecklistItem.find params[:group_id]
    @record = @equipment.start_maintenance current_user, params[:group_id]
  end

  def create
    @equipment = @equipment_type.equipments.build equipment_params
    if @equipment.save
      render json: @equipment.to_json(include: :attachment), status: 200
    else
      render json: @equipment.errors.full_messages.to_sentence, status: 422
    end
  end

  def update
    @equipment = @equipment_type.equipments.find params[:id]
    if @equipment.update_attributes equipment_params
      @equipment.reload
      render json: @equipment.to_json(include: :attachment), status: 200
    else
      render json: @equipment.errors.full_messages.to_sentence, status: 422
    end
  end

  def destroy
    @equipment = @equipment_type.equipments.find params[:id]
    if @equipment.destroy
      render json: @equipment.id
    else
      render json: {error: 'Failed to delete Equipment Type'}, status: 422
    end
  end

  private

  def get_equipment_type
    @equipment_type = Maintenance::EquipmentType.find params[:equipment_type_id]
  end

  def equipment_params
    params.require(:equipment).permit(
      :name, :make, :location, :buy_date, :replacement_date, :instruction, :warranty, :lifespan, :removed, :row_order_position,
      attachment_attributes: [:id, :file, :_destroy])
  end
end
