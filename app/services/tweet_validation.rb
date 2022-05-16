require 'httparty'

class TweetValidation
  include HTTParty
  CACHE_KEY = 'twitter_too_many_requests'.freeze

  # Two main ways to check presence of a tweet
  # 1) Use Twitter API to check tweet. Note: This is under rate limits.
  # 2) Make a HEAD request to twitter.com. This runs into potential issues of url blocking.
  #
  # Doing 2) in the front end with an AJAX call may be possible, if redirects are handled properly: see https://stackoverflow.com/questions/199099/how-to-manage-a-redirect-request-after-a-jquery-ajax-call
  # However, here we call it from our back-end (method: tweet_is_valid_front_end)

  # Test IDs
  # id = '955454023519391744' # invalid
  # id = '563126182607339520' # valid

  def self.tweet_is_valid?(id)
    if id.nil?
      ErrorLogger.error 'Tweet validation: The tweet id is nil.'
      return false
    end
    return tweet_is_valid_front_end?(id) if Rails.cache.exist?(CACHE_KEY)

    Crowdbreaks::TwitterClient.status(id)
  rescue Twitter::Error::TooManyRequests => e
    ErrorLogger.error "Tweet validation: Twitter error. #{e.class}: #{e.message} Validating with Twitter front-end."
    Rails.cache.write(CACHE_KEY, 1, expires_in: 1.hour)
    tweet_is_valid_front_end?(id)
  rescue Twitter::Error::ClientError => e
    ErrorLogger.error "Tweet validation: Twitter client error. #{e.class}: #{e.message}"
    # Tweet is not available anymore or bad authentication
    false
  rescue Twitter::Error => e
    ErrorLogger.error "Tweet validation: Twitter error. #{e.class}: #{e.message} Validating with Twitter front-end."
    tweet_is_valid_front_end?(id)
  else
    true
  end

  def self.tweet_is_valid_front_end?(id)
    # Check validity of tweet first by making a HEAD request to
    Rails.logger.info 'Checking the tweet using the Twitter front end'
    url = "https://twitter.com/user/status/#{id}"
    self.class.head(url).response.code == '200'
  rescue StandardError => e
    ErrorLogger.error "Twitter client error. #{e.class}: #{e.message}"
  end
end
