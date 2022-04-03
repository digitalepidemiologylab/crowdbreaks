class Task < ApplicationRecord
  belongs_to :mturk_batch_job
  has_many :results, dependent: :delete_all
  belongs_to :mturk_worker, optional: true
  belongs_to :mturk_tweet, optional: true

  enum lifecycle_status: %i[unsubmitted submitted assigned completed]
  STATUS_LABELS = {
    unsubmitted: 'label-default',
    submitted: 'label-primary',
    completed: 'label-info'
  }.freeze

  def update_after_hit_submit(hit_creation_time)
    update_attributes!({ time_submitted: hit_creation_time, lifecycle_status: :submitted })
  end

  def update_after_hit_assignment
    update_attributes!({ time_assigned: Time.current, lifecycle_status: :assigned })
  end

  def update_on_final(tasks_params)
    Rails.logger.info(
      "Task #{id}: Worker #{tasks_params[:worker_id]} has submitted results for #{tasks_params[:tweet_id]}")
    if mturk_worker&.worker_id != tasks_params[:worker_id]
      ErrorLogger.error(
        "Task #{id} for #{tasks_params[:hit_id]} was assigned to worker #{mturk_worker.worker_id} and is now " \
        "re-assigned to worker #{tasks_params[:worker_id]}."
      )
      update_attributes!({ mturk_worker_id: MturkWorker.find_or_create_by(worker_id: tasks_params[:worker_id]).id })
    end

    if mturk_tweet.tweet_id.to_s != tasks_params[:tweet_id]
      new_hit_id = Task.find_by(hit_id: tasks_params[:hit_id])&.hit_id
      ErrorLogger.error(
        "Task #{id} done by worker #{tasks_params[:worker_id]} was for tweet #{mturk_tweet.tweet_id} and is now " \
        "re-assigned to tweet #{tasks_params[:tweet_id]}. Batch: #{mturk_batch_job.name}."
      )
      update_attributes!({ mturk_tweet_id: MturkTweet.find_by(tweet_id: tasks_params[:tweet_id]).id })
    end
    update_attributes!({ time_completed: Time.current, lifecycle_status: :completed })
  end

  def unassign
    update_attributes({ mturk_tweet_id: nil, mturk_worker_id: nil, time_assigned: nil, lifecycle_status: :submitted })
  end

  def hit
    return unless hit_id.present?

    Mturk.new(sandbox: mturk_batch_job.sandbox).get_hit(hit_id)
  end

  def hit_review_status
    hit.try(:hit_review_status)
  end

  def hit_status
    hit.try(:hit_status)
  end

  def delete_hit
    return unless hit_id.present?

    Mturk.new(sandbox: mturk_batch_job.sandbox).delete_hit(hit_id, expire: true)
  end
end
