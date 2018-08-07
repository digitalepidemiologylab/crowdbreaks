class MturkWorker < ApplicationRecord
  has_many :tasks
  has_many :mturk_tweets, through: :tasks

  def assign_task(task)
    # retrieve a tweet which has never been labelled
    tweets_in_batch = task.mturk_batch_job.mturk_tweets
    mturk_tweet = tweets_in_batch.unassigned.first

    if mturk_tweet.nil?
      # all tweets have been labelled at least once, pick tweets not done by worker
      tweets_unassigned_to_worker = tweets_in_batch.not_assigned_to_worker(worker_id)
      # and is below assignment threshold
      threshold = task.mturk_batch_job.number_of_assignments
      mturk_tweet = tweets_unassigned_to_worker.num_assignments_below(threshold).first
    end

    return if mturk_tweet.nil?
    
    # assign the task
    task.update_attributes({
      mturk_worker_id: id,
      mturk_tweet_id: mturk_tweet.try(:id),
      time_assigned: Time.zone.now
    })
  end
end
