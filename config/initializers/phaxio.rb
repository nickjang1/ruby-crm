  Phaxio.config do |config|
    config.api_key = ENV['PHAXIO_API_KEY'] || Settings.phaxio_api_key
    config.api_secret = ENV['PHAXIO_API_SECRET'] || Settings.phaxio_api_secret
  end
