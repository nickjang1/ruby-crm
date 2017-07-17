class CorporateConnectionsMailer < ApplicationMailer

  def new_connection_notification(connection_id)
    @connection = Corporate::Connection.find connection_id
    @user       = @connection.corp_user
    @property   = Property.current

    mail(to: @user.email, subject: "New connections invitation from #{ @property.name }")
  end

end
