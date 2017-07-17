class Maintenance::EquipmentTypesController < Maintenance::BaseController

  def index
    @equipment_types = Maintenance::EquipmentType.active.includes(:checklist_groups, :active_equipments)
    render json: @equipment_types.to_json(include: [{checklist_groups: {include: :checklist_items}}, :attachment, {active_equipments: {include: :attachment}}])
  end

  def create
    @equipment_type = Maintenance::EquipmentType.new equipment_type_params.merge!(user_id: current_user.id)
    if @equipment_type.save
      render json: @equipment_type.to_json(include: [{checklist_groups: {include: :checklist_items}}, :attachment, {equipments: {include: :attachment}}])
    else
      render json: @equipment_type.errors.full_messages.to_sentence, status: 422
    end
  end

  def update
    @equipment_type = Maintenance::EquipmentType.find params[:id]
    if @equipment_type.update_attributes equipment_type_params
      @equipment_type.reload
      render json: @equipment_type.to_json(include: [{checklist_groups: {include: :checklist_items}}, :attachment, {equipments: {include: :attachment}}])
    else
      render json: @equipment_type.errors.full_messages.to_sentence, status: 422
    end
  end

  def destroy
    @equipment_type = Maintenance::EquipmentType.find params[:id]
    if @equipment_type.destroy
      render json: @equipment_type.id
    else
      render json: {error: 'Failed to delete Equipment Type'}, status: 422
    end
  end

  private
  def equipment_type_params
    params.require(:equipment_type).permit(:name, :row_order_position, :instruction, attachment_attributes: [:id, :file, :_destroy])
  end

end