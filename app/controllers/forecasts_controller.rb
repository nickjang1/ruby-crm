class ForecastsController < ApplicationController


  def index
    @weeks_per_view = 4
    @current_week = Date.new(params[:year].to_i,params[:month].to_i,params[:day].to_i) if params[:year].present? && params[:month].present? && params[:day].present?
    @current_week ||= Date.current.beginning_of_week
    @last_week = @current_week - 1.week
    @next_week = @current_week + 1.week
    @room = RoomType.new
  end

  def update
    @room = current_property.room_types.find(params[:room_type_id])
    @forecast = @room.occupancies.where(:date => Date.parse(params[:week_start])).first_or_create

    if params[:type] == "forecast"
      @forecast.update_attributes(forecast: params[:occupancy])
    elsif params[:type] == "actual"
      @forecast.update_attributes(actual: params[:occupancy])
    end
  end

end
