class Task < ApplicationRecord
  belongs_to :mturk_batch_job
  has_many :results, dependent: :delete_all
  belongs_to :mturk_worker, optional: true
  belongs_to :mturk_tweet, optional: true

  enum lifecycle_status: [:unsubmitted, :submitted, :assigned, :completed]
  STATUS_LABELS = {
    unsubmitted: 'label-default',
    submitted: 'label-primary',
    completed: 'label-info'
  }

  def update_after_hit_submit(hit_creation_time)
    self.update_attributes!({
      time_submitted: hit_creation_time,
      lifecycle_status: :submitted,
    })
  end

  def update_after_hit_assignment
    self.update_attributes!({
      time_assigned: Time.current,
      lifecycle_status: :assigned,
    })
  end

  def update_on_final(tasks_params)
    if mturk_tweet_id.nil? or mturk_worker_id.nil?
      # this should be set normally, update manually
      Rails.logger.error("Task for #{tasks_params[:hit_id]} has missing worker and tweet information.")
      self.update_attributes({
        mturk_tweet_id: MturkTweet.find_by(tweet_id: tasks_params[:tweet_id]).id,
        mturk_worker_id: MturkWorker.find_by(worker_id: tasks_params[:worker_id]).id
      })
    end
    update_attributes({
      time_completed: Time.current,
      lifecycle_status: :completed
    })
  end

  def unassign
    self.update_attributes({
      mturk_tweet_id: nil,
      mturk_worker_id: nil,
      time_assigned: nil,
      lifecycle_status: :submitted,
    })
  end

  def hit
    if hit_id.present?
      Mturk.new(sandbox: mturk_batch_job.sandbox).get_hit(hit_id)
    end
  end

  def hit_review_status
    hit.try(:hit_review_status)
  end

  def hit_status
    hit.try(:hit_status)
  end

  def delete_hit
    if hit_id.present?
      Mturk.new(sandbox: mturk_batch_job.sandbox).delete_hit(hit_id)
    end
  end
end
