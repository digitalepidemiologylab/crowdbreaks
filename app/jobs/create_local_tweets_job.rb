class CreateLocalTweetsJob < ApplicationJob
  queue_as :default

  def perform(local_batch_job_id, user_id, tweet_rows, destroy_first: false)
    local_batch_job = LocalBatchJob.find_by(id: local_batch_job_id)
    return if local_batch_job.nil?

    if destroy_first
      local_batch_job.local_tweets.delete_all
    end

    total_count = tweet_rows.count
    if total_count > 0
      tv = TweetValidation.new
      pn = ProgressNotifier.new(local_batch_job_id, user_id, 'local-tweets', total_count)
      pn.start
      tweet_rows.each_with_index do |row, i|
        lt = LocalTweet.create(tweet_id: row[0], tweet_text: row.length == 1 ? "" : row[1], local_batch_job_id: local_batch_job_id)
        if local_batch_job.do_check_availability?
          if tv.tweet_is_valid?(row[0])
            lt.available!
          else
            lt.unavailable!
          end
        end
        pn.update(i)
      end
      pn.finish
    end
  end

end
