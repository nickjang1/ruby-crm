class Maintenance::EquipmentChecklistItemsController < Maintenance::BaseController
  before_filter :get_equipment_type

  def create
    @checklist_item = @equipment_type.checklist_items.build checklist_item_params
    if @checklist_item.save
      render json: @checklist_item.to_json(include: :checklist_items), status: 200
    else
      render json: @checklist_item.errors.full_messages.to_sentence, status: 422
    end
  end

  def show
    @checklist_item = @equipment_type.checklist_items.find params[:id]
    render json: @checklist_item.to_json(include: :checklist_items), status: 200
  end

  def update
    @checklist_item = @equipment_type.checklist_items.find params[:id]
    if @checklist_item.update_attributes checklist_item_params
      render json: @checklist_item.to_json(include: :checklist_items), status: 200
    else
      render json: @checklist_item.errors.full_messages.to_sentence, status: 422
    end
  end

  def destroy
    @checklist_item = @equipment_type.checklist_items.find params[:id]
    if @checklist_item.destroy
      render json: @checklist_item.id
    else
      render json: {error: 'Failed to delete Equipment Type'}, status: 422
    end
  end

  private

  def get_equipment_type
    @equipment_type = Maintenance::EquipmentType.find params[:equipment_type_id]
  end

  def checklist_item_params
    params.require(:checklist_item).permit(:name, :frequency, :tools_required, :group_id, :row_order_position)
  end
end
