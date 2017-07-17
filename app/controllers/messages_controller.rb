class MessagesController < ApplicationController
  around_filter :action_with_property, only: [:index]

  respond_to :json

  def index
    messagable = params[:model_type].classify.constantize.find(params[:model_id])
    @messages = messagable.messages
    @messages.build(
      user_id: messagable.closed_by_user_id,
      body: "(Closing Comment) #{messagable.closing_comment}",
      created_at: messagable.closed_at
    ) if messagable.is_a?(Maintenance::WorkOrder) && messagable.closed? && messagable.closing_comment.present?
    @messages = @messages.to_a.sort_by(&:created_at).reverse!
  end

  def create
    @message = Message.new body: params[:body], attachment: params[:attachment]
    @message.user = current_user
    @message.messagable_type = params[:model_type]
    @message.messagable_id = params[:model_id]
    if @message.save
      render action: 'show'
    else
      render json: {error: 'Failed to add message'}, status: :unprocessable_entity
    end
  end

end
