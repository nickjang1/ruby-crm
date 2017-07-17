class Engage::EntitiesController < ApplicationController
  include SentientController

  before_action :authenticate_user!
  around_filter :property_time_zone
  before_action :get_date, only: [:index, :create, :update]
  before_action :get_entity, only: [:update, :destroy]

  def index
    @entities = Engage::Entity.send(params[:type].downcase.to_sym, @date)
    render json: @entities.as_json(user: current_user, date: @date)
  end

  def create
    @entity = current_user.engage_entities.build entity_params
    if @entity.save
      render json: @entity.as_json(user: current_user, date: @date)
    else
      render json: @entity.errors.full_messages.to_sentence, status: :unprocessable_entity
    end
  end

  def update
    if @entity.update_attributes(entity_params)
      render json: @entity.as_json(user: current_user, date: @date)
    else
      render json: @entity.errors.full_messages.to_sentence, status: :unprocessable_entity
    end
  end

  def destroy
    @entity.destroy
    head :ok
  end

  private

  def entity_params
    params.require(:entity).permit(
      :room_number, :body, :entity_type, :due_date, :status, :complete, metadata: []
    )
  end

  def get_entity
    @entity = Engage::Entity.find params[:id]
  end

  def get_date
    @date = Date.parse(params[:date] || Date.today.to_s)
  end
end
