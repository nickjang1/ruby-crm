class Maintenance::MaterialsController < Maintenance::BaseController

  def index
    render json: 'No items in Maintenance category', status: :unprocessable_entity and return if Category.maintenance.nil?
    @items = Category.maintenance.items.active
    @items = @items.search_columns(:name, params[:search]) if params[:search].present?

    render json: @items.to_json(
             only: [:id, :name],
             include: {inventory_unit: {only: :name}},
             methods: [:purchase_price]
           )
  end

  def create
    @material = Maintenance::Material.new material_params
    if @material.save
      render partial: 'maintenance/materials/material', locals: {m: @material}
    else
      render json: 'Failed to save material.', status: :unprocessable_entity
    end
  end

  def update
    @material = Maintenance::Material.find params[:id]
    if @material.update material_params
      render json: @material.to_json
    else
      render json: 'Failed to update material.', status: :unprocessable_entity
    end
  end

  def destroy
    @material = Maintenance::Material.find params[:id]
    if @material.destroy
      render json: @material.to_json
    else
      render json: 'Failed to delete material', status: :unprocessable_entity
    end
  end

  private

  def material_params
    params.require(:maintenance_material).permit(:work_order_id, :item_id, :quantity, :price)
  end

end