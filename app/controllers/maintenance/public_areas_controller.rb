class Maintenance::PublicAreasController < Maintenance::BaseController
  add_breadcrumb I18n.t('controllers.maintenance.public_areas.index'), :maintenance_public_areas_path, only: [:index, :show]
  add_breadcrumb I18n.t('controllers.maintenance.public_areas.inspection'), :inspection_maintenance_public_areas_path, only: [:inspection, :inspect]
  before_action :set_public_area, only: [:update, :destroy, :checklist_items, :inspect]
  before_filter :authorize_maintenance, only: [:index, :show]
  before_filter :authorize_inspection, only: [:inspection, :inspect]

  def index
    authorize :access, :pm?
    respond_to do |format|
      format.html
      format.json do
        filter_type = params[:filter_type]
        @public_areas =
          if filter_type == 'missed'
            (cycle = Maintenance::Cycle.previous(:public_area)) && cycle.public_areas_remaining.by_progress || []
          elsif filter_type == 'remaining'
            (cycle = Maintenance::Cycle.current(:public_area)) && cycle.public_areas_remaining.by_progress || []
          elsif filter_type == 'in_progress'
            (cycle = Maintenance::Cycle.current(:public_area)) && cycle.public_areas_in_progress.by_progress || []
          elsif filter_type == 'completed'
            (cycle = Maintenance::Cycle.current(:public_area)) && cycle.public_areas_completed.by_progress || []
          else
            Maintenance::PublicArea.areas_with_subcategories
          end

        render json: @public_areas.to_json
      end
    end
  end
  
  def show
    authorize :access, :pm?
    @public_area = Maintenance::PublicArea.find_by_name(params[:id].gsub("-","/").gsub("_"," "))
    @record = @public_area.start_maintenance current_user
    add_breadcrumb I18n.t('controllers.maintenance.public_areas.show', name: @public_area.name)
  end
  
  def create
    @public_area = Maintenance::PublicArea.new public_area_params
    @public_area.user_id = current_user.id
    @public_area.save
    render json: @public_area.to_json(only: [:id, :name]), status: 200
  end
  
  def update
    @public_area.update public_area_params
    render nothing: true, status: 200
  end
  
  def destroy
    @public_area.update_attribute(:is_deleted,true) 
    render nothing: true, status: 200
  end
  
  def checklist_items
    @public_areas = @public_area.checklist_items
    render json: @public_areas.to_json, status: 200
  end

  def inspection
    authorize :access, :inspection?
    respond_to do |format|
      format.html
      format.json do
        @public_areas = Maintenance::Cycle.current(:public_area) && Maintenance::Cycle.current(:public_area).public_areas_to_inspect || []
        render json: @public_areas.to_json
      end
    end
  end

  def inspect
    authorize :access, :inspection?
    if @public_area
      @record = @public_area.start_inspection
      add_breadcrumb @public_area.name
    else
      flash[:error] = 'No public area found'
      redirect_to inspection_maintenance_public_areas_path
    end
  end
  
  private
  
  def public_area_params
    params.require(:public_area).permit(:id,:name,:row_order_position)
  end
  
  def set_public_area
    @public_area = Maintenance::PublicArea.find params[:id]
  end
end
