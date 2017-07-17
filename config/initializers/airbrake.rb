Airbrake.configure do |config|
  config.api_key = ENV['AIRBRAKE_API_KEY'] || Settings.airbrake_api_key
  config.ignore_only  = []
end
