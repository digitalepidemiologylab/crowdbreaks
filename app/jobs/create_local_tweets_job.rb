require 'csv'

class CreateLocalTweetsJob < ApplicationJob
  queue_as :default

  after_enqueue do |job|
    local_batch_job = LocalBatchJob.find_by(id: job.arguments.first)
    local_batch_job.update_attribute(:processing, true)
  end

  after_perform do |job|
    local_batch_job = LocalBatchJob.find_by(id: job.arguments.first)
    local_batch_job.update_attribute(:processing, false)
  end

  def perform(local_batch_job_id, tweet_ids, destroy_first: false)
    local_batch_job = LocalBatchJob.find_by(id: local_batch_job_id)
    return if local_batch_job.nil?

    if destroy_first
      local_batch_job.local_tweets.destroy_all
    end

    tweet_ids.each do |tweet_id|
      LocalTweet.create(tweet_id: tweet_id, local_batch_job_id: local_batch_job_id)
    end
  end
end
