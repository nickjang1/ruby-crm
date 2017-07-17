class Engage::MessagesController < ApplicationController
  include SentientController

  before_action :authenticate_user!
  around_filter :property_time_zone
  before_action :get_date, only: [:index, :create, :update]
  before_action :get_message, only: [:update]

  def index
    @messages = Engage::Message.threads.occurred_on(@date).includes(:work_order, :created_by, :completed_by, replies: [:created_by])
    render json: @messages.as_json(user: current_user, date: @date)
  end

  def create
    @message = current_user.engage_messages.build message_params
    if @message.save
      render json: @message.as_json(user: current_user, date: @date)
    else
      render json: @messages.errors.full_messages.to_sentence, status: :unprocessable_entity
    end
  end

  def update
    if @message.update_attributes(message_params)
      render json: @message.as_json(user: current_user, date: @date)
    else
      render json: @messages.errors.full_messages.to_sentence, status: :unprocessable_entity
    end
  end

  private

  def message_params
    params.require(:message).permit(
      :room_number, :title, :body, :parent_id, :follow_up_start, :follow_up_end,
      :broadcast_start, :broadcast_end, :like, :complete, :work_order_id
    )
  end

  def get_message
    @message = Engage::Message.find params[:id]
  end

  def get_date
    @date = Date.parse(params[:date] || Date.today.to_s)
  end
end
