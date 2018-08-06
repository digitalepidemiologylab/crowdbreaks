class MturkWorker < ApplicationRecord
  has_many :tasks
  has_many :mturk_tweets, through: :tasks

  def assign_task(task)
    # retrieve a tweet which has never been labelled
    tweets_in_batch = task.mturk_batch_job.mturk_tweets
    mturk_tweet = tweets_in_batch.unassigned.first

    if mturk_tweet.nil?
      # all tweets have been labelled at least once, pick tweets not done by worker
      potential_tweet_ids = (tweets_in_batch - tweets_in_batch.assigned_to_worker(worker_id)).pluck(:tweet_id)
      # among those pick below threshold
      mturk_tweet = MturkTweet
        .where(tweet_id: potential_tweet_ids)
        .num_assignments_below(task.mturk_batch_job.number_of_assignments)
        .first
    end

    return if mturk_tweet.nil?
    
    # assign the task
    task.update_attributes({
      mturk_worker_id: id,
      mturk_tweet_id: mturk_tweet.try(:id),
      time_assigned: Time.now
    })
  end


end
