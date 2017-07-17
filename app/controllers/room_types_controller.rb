class RoomTypesController < ApplicationController
  def new
    @room = RoomType.new
  end

  def create
    @room = current_property.room_types.create(room_type_params)
  end

  private

  def room_type_params
    params.require(:room_type).permit(:name, :max_occupancy, :min_occupancy, :average_occupancy)
  end
end
