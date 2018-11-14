class MturkWorker < ApplicationRecord
  has_many :tasks
  has_many :mturk_tweets, through: :tasks

  def assign_task(task)
    # case worker has reached max_tasks_per_worker
    max_tasks_per_worker = task.mturk_batch_job.max_tasks_per_worker
    if not max_tasks_per_worker.nil?
      if task.mturk_batch_job.mturk_tweets.assigned_to_worker(worker_id).count >= max_tasks_per_worker
        Rails.logger.debug "Max number of tasks has been reached for this worker" 
        return
      end
    end

    # retrieve potential new tweet for worker
    mturk_tweet = retrieve_mturk_tweet_for_task(task)
    
    # case all tasks have been completed
    if mturk_tweet.nil?
      Rails.logger.info "All tasks have beeen completed."
      return
    end

    if task.mturk_batch_job.check_availability_after? or task.mturk_batch_job.check_availability_before_and_after?
      # Loop as long as we find a valid tweet (avoid infinite loop with max_trials in case something goes wrong)
      c = 0
      max_trials = task.mturk_batch_job.mturk_tweets.count
      Rails.logger.debug "Number of tweets for this batch: #{max_trials}" 
      tv = TweetValidation.new
      while not tv.tweet_is_valid?(mturk_tweet.tweet_id) and c < max_trials 
        Rails.logger.info "Tweet with ID #{mturk_tweet.tweet_id} was found to be unavailable. Setting to unavailable and trying to find new tweet." 
        mturk_tweet.unavailable!
        mturk_tweet = retrieve_mturk_tweet_for_task(task)
        if mturk_tweet.nil?
          Rails.logger.info "All tasks have beeen completed."
          return
        end
        c += 1
        if c == max_trials
          Rails.logger.info "Reached max_trials"
        end
      end
      # setting tweet to available
      mturk_tweet.available!
    end
    
    # assign the task
    Rails.logger.info "Found valid tweet to be #{mturk_tweet.tweet_id}"
    task.update_attributes({
      mturk_worker_id: id,
      mturk_tweet_id: mturk_tweet.id
    })
    task.update_after_hit_assignment
  end


  private

  def retrieve_mturk_tweet_for_task(task)
    # This method will retrieve a new tweet for this worker given a task given the following conditions.
    # 1. Tweet should be marked as available and belong to batch of given task
    # 2. Tweet has not been labelled more than local_batch_job.number_of_assignments times
    # 3. Tweet has not been previously worked on by worker

    Rails.logger.info "Retrieving new tweet for worker/task pair" 
    # retrieve a tweet among those which have never been labelled and are available
    ActiveRecord::Base.uncached() do
      if task.mturk_batch_job.check_availability_after? or task.mturk_batch_job.check_availability_before_and_after?
        # consider tweets which have been determined to be available or are still unkown
        available_in_batch = task.mturk_batch_job.mturk_tweets.may_be_available
      elsif task.mturk_batch_job.check_availability_before?
        # consider only tweets which have been determined to be available
        # available_in_batch = task.mturk_batch_job.mturk_tweets.available
        available_in_batch = task.mturk_batch_job.mturk_tweets.may_be_available
      else
        # consider all tweets in batch
        available_in_batch = task.mturk_batch_job.mturk_tweets
      end
      mturk_tweet = available_in_batch.unassigned.first
      if mturk_tweet.nil?
        Rails.logger.info "All tweets have been assigned at least once. Selecting from multi-labelled pool... " 
        # all tweets have been labelled at least once, pick tweets not done by worker
        tweets_unassigned_to_worker = available_in_batch.not_assigned_to_worker(worker_id)
        # and is below assignment threshold
        threshold = task.mturk_batch_job.number_of_assignments
        mturk_tweet = tweets_unassigned_to_worker.num_assignments_below(threshold).first
        if mturk_tweet.nil?
          Rails.logger.info "... No tweets could be found in multi-labelled pool." 
        else
          Rails.logger.info "... Successfully found tweet in multi-labelled pool." 
        end
      end
      mturk_tweet
    end
  end
end
