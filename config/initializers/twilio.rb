Twilio.configure do |config|
  config.account_sid = ENV['TWILIO_ACCOUNT_SID'] || Settings.twilio_account_sid
  config.auth_token = ENV['TWILIO_AUTH_TOKEN'] || Settings.twilio_auth_token
end

TWILIO = TwilioClient.new