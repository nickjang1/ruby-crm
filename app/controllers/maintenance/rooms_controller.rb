class Maintenance::RoomsController < Maintenance::BaseController

  before_filter :get_room, only: [:show, :inspect]
  before_filter :authorize_maintenance, only: [:index, :show]
  before_filter :authorize_inspection, only: [:inspection, :inspect]
  skip_before_action :check_current_cycles_are_finished, only: [:create]
  add_breadcrumb I18n.t('controllers.maintenance.rooms.index'), :maintenance_rooms_path, only: [:index, :show]
  add_breadcrumb I18n.t('controllers.maintenance.rooms.inspection'), :inspection_maintenance_rooms_path, only: [:inspection, :inspect]

  def index
    respond_to do |format|
      format.html
      format.json do
        @rooms_by_floors =
            if params[:filter_type] == 'missed'
              Maintenance::Cycle.previous && Maintenance::Cycle.previous.rooms_remaining.by_floors || []
            elsif params[:filter_type] == 'remaining'
              Maintenance::Cycle.current && Maintenance::Cycle.current.rooms_remaining.by_floors || []
            elsif params[:filter_type] == 'in_progress'
              Maintenance::Cycle.current && Maintenance::Cycle.current.rooms_in_progress.by_floors || []
            elsif params[:filter_type] == 'completed'
              Maintenance::Cycle.current && Maintenance::Cycle.current.rooms_completed.by_floors || []
            else
              rooms = Maintenance::Room.by_floors(false)
            end
        render json: @rooms_by_floors.to_json
      end
    end
  end

  def show
    if request.format.html?
      if @room
        @record = @room.start_maintenance current_user
        add_breadcrumb I18n.t('controllers.maintenance.rooms.show', room_number: @room.room_number)
      else
        flash[:error] = "No guest room found"
        redirect_to maintenance_rooms_path
      end
    elsif request.format.json?
      @room = Maintenance::Room.find(params[:id])
      render json: @room.latest_maintenance_record
    end
  end

  def create
    created_rooms = nil
    ActiveRecord::Base.transaction do
      #params[:rooms].each { |room| Maintenance::Room.create room[1].merge(user_id: current_user.id) }
      created_rooms = Maintenance::Room.create params[:rooms].permit!.values.map{|room_params| room_params.merge(user_id: current_user.id)} 
    end
    # @room = Maintenance::Room.new room_params
    # @room.user_id = current_user.id
    # @room.save
    render json: created_rooms.to_json, status: 200
  end

  def update 
    @room = Maintenance::Room.find params[:id]
    if @room.update(room_number: params[:value])
      head 200
    else
      render text: @room.errors.full_messages.to_sentence, status: 400
    end
  end

  def inspection
    respond_to do |format|
      format.html
      format.json do
        @rooms_by_floors =
          Maintenance::Cycle.current && Maintenance::Cycle.current.rooms_to_inspect || []
        render json: @rooms_by_floors.to_json
      end
    end
  end

  def inspect
    if @room
      @record = @room.start_inspection
      add_breadcrumb I18n.t('controllers.maintenance.rooms.show', room_number: @room.room_number)
    else
      flash[:error] = "No guest room found"
      redirect_to maintenance_rooms_path
    end
  end

  private

  def room_params
    params.require(:room).permit(:floor, :room_number)
  end

  def get_room
    if /^floor[A-z0-9]+(-)room[A-z0-9]+/.match(params[:id]) != nil
      rooms = Maintenance::Room.where(:floor=>params[:id].split('-')[0].gsub("floor", ""),:room_number=>params[:id].split('-')[1].gsub("room", ""))
      @room = rooms.first unless rooms.blank?
    end
  end

end
