class CorporateConnectionsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize

  def new
    if current_property.corporate_connection
      redirect_to corporate_connections_path and return
    end
    add_breadcrumb t('controllers.corporate_connections.settings'), property_settings_path
    add_breadcrumb t('controllers.corporate_connections.connect_to_corporate')
    @connection = Corporate::Connection.new
  end

  def show
    add_breadcrumb t('controllers.corporate_connections.settings'), property_settings_path
    add_breadcrumb t('controllers.corporate_connections.connect_to_corporate')
    @connection = current_property.corporate_connection
    !@connection && redirect_to(new_corporate_connections_path) and return
    unless @connection.corporate_approved?
      render :show_verification
    else
      render :show_confirm
    end
  end

  def update
    @connection = current_property.corporate_connection
    if params[:approve]
      @connection.approve!
      flash[:notice] = t('controllers.corporate_connections.connected_successfully')
    elsif params[:reject]
      @connection.reject!
      flash[:notice] = t('controllers.corporate_connections.connection_declined')
    end

    redirect_to :property_settings
  end

  def create
    @connection = current_property.build_corporate_connection(create_attributes)
    if @connection.valid?
      user = @connection.corp_user
      if user
        @connection.corporate_id  = user.corporate_id
        @connection.created_by_id = current_user.id
        @connection.save
        CorporateConnectionsMailer.delay.new_connection_notification(@connection.id)
        redirect_to corporate_connections_path
      else
        flash.now[:alert] = t('controllers.corporate_connections.no_such_user')
        render :new
      end 
    else
      flash.now[:alert] = @connection.errors.full_messages.to_sentence
      render :new
    end
  end

  private

  def authorize
    authorize!params[:action], Corporate::Connection
  end

  def create_attributes
    params.require(:corporate_connection).permit(:email, :email_confirmation)
  end
end
