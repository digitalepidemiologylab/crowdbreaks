class CreateLocalTweetsJob < ApplicationJob
  queue_as :default

  # Creates <tt>LocalTweet</tt> objects linked to the <tt>local_batch_job_id</tt> for the given <tt>tweet_rows</tt>
  # (extracted previously from a CSV file which is uploaded to the <tt>LocalBatchJob</tt> form)
  def perform(local_batch_job_id, user_id, tweet_rows, destroy_first: false)
    local_batch_job = LocalBatchJob.find_by(id: local_batch_job_id)
    return if local_batch_job.nil?

    local_batch_job.local_tweets.delete_all if destroy_first

    total_count = tweet_rows.count
    return unless total_count.positive?

    pn = ProgressNotifier.new(local_batch_job_id, user_id, 'local-tweets', total_count)
    pn.start
    tweet_rows.each_with_index do |row, i|
      lt = LocalTweet.create(tweet_id: row[0], tweet_text: row.length == 1 ? '' : row[1], local_batch_job_id: local_batch_job_id)
      if local_batch_job.do_check_availability?
        if TweetValidation.tweet_is_valid?(row[0])
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
