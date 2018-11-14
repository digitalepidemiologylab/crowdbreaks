class RefreshMturkTweetsAvailabilityJob < ApplicationJob
  queue_as :default

  def perform(mturk_batch_job_id, user_id)
    mturk_batch_job = MturkBatchJob.find_by(id: mturk_batch_job_id)
    unknown_tweets = mturk_batch_job.mturk_tweets.where(availability: :unknown)
    tv = TweetValidation.new
    unknown_tweets.each do |mturk_tweet|
      if tv.tweet_is_valid?(mturk_tweet.tweet_id)
        mturk_tweet.available!
      else
        mturk_tweet.unavailable!
      end
    end
    ActionCable.server.broadcast("job_notification:#{user_id}", job_status: 'completed', job_type: 'refresh_mturk_tweets')
  end
end
