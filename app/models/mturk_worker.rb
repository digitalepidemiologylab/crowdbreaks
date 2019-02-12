class MturkWorker < ApplicationRecord
  has_many :tasks
  has_many :mturk_tweets, through: :tasks
  has_many :results, through: :tasks

  enum status: [:default, :blacklisted, :blocked], _suffix: true

  def assign_task(task)
    # Find a suitable tweet to match to a worker-task pair. There are the following possible cases which need to be handled:
    # a) Worker has reached max_tasks_per_worker --> exclude worker
    # b) There are no more available tweets left in batch (all tweets left have been set to unavailable) --> exclude worker
    # c) There are available tweets left, but worker has already seen all the tweets in this batch (happens when max_tasks_per_worker > num_tasks) --> exclude worker
    # d) All available tweets have already been annotated max_assignments times (this should not occur since the number of tasks should correspond to the number of HITs) --> return the tweet with the lowest number of annotations which hasn't been seen by this worker
   
    # Generate handler for Mturk notifications
    mturk_notification = MturkNotification.new
    
    # case worker has reached max_tasks_per_worker
    max_tasks_per_worker = task.mturk_batch_job.max_tasks_per_worker
    if not max_tasks_per_worker.nil?
      if task.mturk_batch_job.mturk_tweets.assigned_to_worker(worker_id).count >= max_tasks_per_worker
        Rails.logger.info "Max number of tasks has been reached for worker #{worker_id}" 
        exclude_worker(task.mturk_batch_job)
        return nil, mturk_notification.max_tasks_by_worker_reached
      end
    end

    if task.assigned?
      Rails.logger.info "Task has been previously assigned to someone else."
      if task.results.count > 0
        msg = "Task #{task.id} already has associated results and can not be given to #{worker_id}. The previous results were done by worker #{task.mturk_worker.worker_id}."
        worker_id == task.mturk_worker.worker_id ? Rails.logger.error(msg) : ErrorLogger.error(msg)  # only report to rollbar in case of wrong worker assignment
        task.completed!
        return nil, mturk_notification.error
      end
      # Task was previously assigned to someone else (who didn't complete task). Unlink previous worker
      task.unassign
      task.reload
    end

    if task.completed?
      ErrorLogger.error "Task #{task.id} has already been completed."
      return nil, mturk_notification.error
    end

    # retrieve potential new tweet for worker
    mturk_tweet = retrieve_mturk_tweet_for_task(task)
    if mturk_tweet.nil?
      exclude_worker(task.mturk_batch_job)
      return nil, mturk_notification.all_tasks_finished
    end

    if task.mturk_batch_job.check_availability_after? or task.mturk_batch_job.check_availability_before_and_after?
      # Loop as long as we find a valid tweet (avoid infinite loop with max_trials in case something goes wrong)
      c = 0
      max_trials = task.mturk_batch_job.mturk_tweets.count
      tv = TweetValidation.new
      while not tv.tweet_is_valid?(mturk_tweet.tweet_id) and c < max_trials 
        Rails.logger.info "Tweet with ID #{mturk_tweet.tweet_id} was found to be unavailable. Setting to unavailable and trying to find new tweet." 
        mturk_tweet.unavailable!
        mturk_tweet = retrieve_mturk_tweet_for_task(task)
        if mturk_tweet.nil?
          exclude_worker(task.mturk_batch_job)
          return nil, mturk_notification.all_tasks_finished
        end
        c += 1
      end
      if mturk_tweet.nil?
        # Unexpected behaviour
        ErrorLogger.error "Search for available tweet was stopped in order to avoid infinite loop."
        return nil, mturk_notification.all_tasks_finished
      end
      # setting tweet to available
      mturk_tweet.available!
    end

    # assign the task
    Rails.logger.info "Found valid tweet to be #{mturk_tweet.tweet_id}"
    task.update_attributes!({
      mturk_worker_id: id,
      mturk_tweet_id: mturk_tweet.id
    })
    task.update_after_hit_assignment
    return mturk_tweet, mturk_notification.success
  end

  def exclude_worker(mturk_batch_job)
    Rails.logger.info "Excluding worker #{worker_id} from batch #{mturk_batch_job.name}." 
    mturk = Mturk.new(sandbox: mturk_batch_job.sandbox)
    mturk.exclude_worker_from_qualification(worker_id, mturk_batch_job.qualification_type_id)
  end

  def block(reason, sandbox: false)
    mturk = Mturk.new(sandbox: sandbox)
    resp = mturk.block_worker(worker_id, reason)
    begin
      resp.successful?
    rescue NoMethodError
      false
    end
  end

  def unblock(sandbox: false)
    mturk = Mturk.new(sandbox: sandbox)
    resp = mturk.unblock_worker(worker_id)
    begin
      resp.successful?
    rescue NoMethodError
      false
    end
  end


  private

  def retrieve_mturk_tweet_for_task(task)
    # This method will retrieve a new tweet for this worker given a task given the following conditions.
    # 1. Tweet should be marked as available and belong to batch of given task
    # 2. Tweet has not been labelled more than local_batch_job.number_of_assignments times
    # 3. Tweet has not been previously worked on by worker
    #
    Rails.logger.info "Retrieving new tweet for worker (#{worker_id})/task (#{task.id}) pair" 
    # retrieve a tweet among those which have never been labelled and are available
    ActiveRecord::Base.uncached() do
      if task.mturk_batch_job.check_availability_after? or task.mturk_batch_job.check_availability_before_and_after?
        # consider tweets which have been determined to be available or are still unkown
        available_in_batch = task.mturk_batch_job.mturk_tweets.may_be_available
      elsif task.mturk_batch_job.check_availability_before?
        # consider tweets which have been determined to be available or are still unkown (this may also be changed to available only)
        available_in_batch = task.mturk_batch_job.mturk_tweets.may_be_available
      else
        # consider all tweets in batch
        available_in_batch = task.mturk_batch_job.mturk_tweets
      end
      if available_in_batch.count == 0
        ErrorLogger.error "Could not find any available tweets in this batch. This will only occur if tasks for unavailable tweets have been generated or some tweets end up not being available at the time of turking and were before. In this case the worker will excluded and be asked to return the HIT."
        return nil
      end
      mturk_tweet = available_in_batch.unassigned.first
      return mturk_tweet unless mturk_tweet.nil?
      # all tweets have been labelled at least once, pick tweets not done by worker
      tweets_unassigned_to_worker = available_in_batch.not_assigned_to_worker(worker_id)
      if tweets_unassigned_to_worker.count == 0
        # Worker has done all tweets for this batch, hence should be excluded
        ErrorLogger.warn "Worker #{worker_id} has done all tweets in this batch. This should normally not happen unless max_tasks_per_worker is higher than the number of tweets in batch." 
        return nil
      end
      # among unassigned to worker select one which is below assignment threshold
      threshold = task.mturk_batch_job.number_of_assignments
      mturk_tweet = tweets_unassigned_to_worker.num_assignments_below(threshold).first
      return mturk_tweet unless mturk_tweet.nil?
      # All of them are below assignment threshold, this should normally not occur since the number of tasks and HITs should be equal. In this case return the unseen HIT with lowest number of assignments
      ErrorLogger.error "Worker #{worker_id} requested new tweet but all available tweets in this batch have already been annotated number_of_assignments (#{threshold}) times. This should normally not occur. Worker will receive unseen tweet with lowest number of annotations." 
      tweets_unassigned_to_worker.order_by_num_assignments.first
    end
  end
end
