require 'httparty'

class TweetValidation
  include HTTParty
  CACHE_KEY = "twitter_too_many_requests"

  # Two main ways to check presence of a tweet
  # 1) Use Twitter API to check tweet. Note: This is under rate limits.
  # 2) Make a HEAD request to twitter.com. This runs into potential issues of url blocking.
  #
  # Doing 2) in the front end with an AJAX call may be possible, if redirects are handled properly: see https://stackoverflow.com/questions/199099/how-to-manage-a-redirect-request-after-a-jquery-ajax-call
  # However, here we call it from our back-end (method: tweet_is_valid_front_end)

  # Test IDs
  # tweet_id = '955454023519391744' # invalid
  # tweet_id = '563126182607339520' # valid


  def tweet_is_valid?(tweet_id)
    return false if tweet_id.nil?
    begin
      if Rails.cache.exist?(CACHE_KEY)
        return tweet_is_valid_front_end?(tweet_id)
      else
        Crowdbreaks::TwitterClient.status(tweet_id)
      end
    rescue Twitter::Error::TooManyRequests => e
      ErrorLogger.error "Too many requests on Twitter API"
      Rails.cache.write(CACHE_KEY, 1, expires_in: 1.hour)
      return tweet_is_valid_front_end?(tweet_id)
    rescue Twitter::Error::ClientError
      # Tweet is not available anymore
      return false
    rescue Twitter::Error => e
      ErrorLogger.error e
      return tweet_is_valid_front_end?(tweet_id)
    else
      return true
    end
  end

  private

  def tweet_is_valid_front_end?(tweet_id)
    # Check validity of tweet first by making a HEAD request to
    begin
      Rails.logger.info 'Checking tweet in front end'
      url = "https://twitter.com/user/status/#{tweet_id}"
      return self.class.head(url).response.code == '200' ? true : false
    rescue StandardError => e
      ErrorLogger.error e
    end
  end
end
