class Corporate::PropertyConnectionsController < Corporate::BaseController
  
  def show
    @connection = current_corporate.connections.find(params[:id])
    redirect_to :corporate_settings and return if @connection.active? or Corporate::Connection::REJECTED_STATES.include?(@connection.state.to_sym)
    unless @connection.corporate_approved?
      render :show_verification
    else
      render :show_confirm
    end
  end

  def update
    @connection = current_corporate.connections.find(params[:id])

    if params[:approve]
      @connection.approve!
    elsif params[:reject]
      @connection.reject!
      flash[:notice] = t('controllers.corporate.property_connections.connection_declined')
      redirect_to corporate_settings_path and return
    end

    redirect_to corporate_property_connection_path(@connection)
  end

end
