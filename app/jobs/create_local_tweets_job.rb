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

  def perform(local_batch_job_id, tweet_rows, destroy_first: false)
    local_batch_job = LocalBatchJob.find_by(id: local_batch_job_id)
    return if local_batch_job.nil?

    if destroy_first
      local_batch_job.local_tweets.delete_all
    end

    if tweet_rows.count > 0
      tweet_rows.each do |row|
        LocalTweet.create(tweet_id: row[0], tweet_text: row.length == 1 ? "" : row[1], local_batch_job_id: local_batch_job_id)
      end
    end
  end
end
