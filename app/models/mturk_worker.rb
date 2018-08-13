class MturkWorker < ApplicationRecord
  has_many :tasks
  has_many :mturk_tweets, through: :tasks

  def assign_task(task)
    mturk_tweet = retrieve_mturk_tweet_for_task(task)
    # all tasks have been completed
    return if mturk_tweet.nil?

    tv = TweetValidation.new
    c = 0
    max_trials = task.mturk_batch_job.mturk_tweets.count + 1
    # Loop as long as we find a valid tweet (avoid infinite loop with max_trials in case something goes wrong)
    while not tv.tweet_is_valid?(mturk_tweet.tweet_id) and c < max_trials 
      mturk_tweet = retrieve_mturk_tweet_for_task(task)
      return if mturk_tweet.nil?
      mturk_tweet.set_to_unavailable
      c += 1
    end
    return if mturk_tweet.nil?
    
    # assign the task
    task.update_attributes({
      mturk_worker_id: id,
      mturk_tweet_id: mturk_tweet.try(:id),
      time_assigned: Time.zone.now
    })
  end


  private

  def retrieve_mturk_tweet_for_task(task)
    # This method will retrieve a new tweet for this worker given a task given the following conditions.
    # 1. Tweet should be marked as available and belong to batch of given task
    # 2. Tweet has not been labelled more than local_batch_job.number_of_assignments times
    # 3. Tweet has not been previously worked on by worker

    # retrieve a tweet among those which have never been labelled and are available
    tweets_in_batch = task.mturk_batch_job.mturk_tweets.is_available
    mturk_tweet = tweets_in_batch.unassigned.first

    if mturk_tweet.nil?
      # all tweets have been labelled at least once, pick tweets not done by worker
      tweets_unassigned_to_worker = tweets_in_batch.not_assigned_to_worker(worker_id)
      # and is below assignment threshold
      threshold = task.mturk_batch_job.number_of_assignments
      mturk_tweet = tweets_unassigned_to_worker.num_assignments_below(threshold).first
    end

    mturk_tweet
  end
end
