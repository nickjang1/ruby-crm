class TwilioClient
  attr_accessor :client

  def initialize()
    @client = Twilio::REST::Client.new
  end

  def send_sms(to, body, from = Settings.twilio_from_number)
    begin
      @client.messages.create(
        from: from,
        to: to,
        body: body
      )
    rescue => e
      Airbrake.notify(e)
      Rails.logger.error "Failed to send SMS to #{to} - #{e.message}"
    end
  end
end