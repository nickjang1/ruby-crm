Pusher.app_id = ENV['PUSHER_APP_ID'] || Settings.pusher_app_id
Pusher.key = ENV['PUSHER_API_KEY'] || Settings.pusher_api_key
Pusher.secret = ENV['PUSHER_API_SECRET'] || Settings.pusher_api_secret
Pusher.logger = Rails.logger
