Crowdbreaks::TwitterClient = Twitter::REST::Client.new do |config|
  config.consumer_key        = ENV['CONSUMER_KEY']
  config.consumer_secret     = ENV['CONSUMER_SECRET']
  config.access_token        = ENV['OAUTH_TOKEN']
  config.access_token_secret = ENV['OAUTH_TOKEN_SECRET']
end
