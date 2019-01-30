class Result < ApplicationRecord
  belongs_to :question
  belongs_to :user
  belongs_to :answer
  belongs_to :project, counter_cache: true
  belongs_to :task, optional: true
  belongs_to :local_batch_job, optional: true
  belongs_to :question_sequence_log, optional: true
  after_create :update_worker_manual_review_status

  scope :counts_by_user, -> (user_id) {where(user_id: user_id).distinct.count(:tweet_id)}
  scope :by_worker, -> (worker_id) { where(id: MturkWorker.find_by(worker_id: worker_id)&.results&.select(:id)) }
  scope :by_batch, -> (batch_name) { where(id: MturkBatchJob.find_by(name: batch_name)&.results&.select(:id)) }

  # group by mturk worker
  scope :group_by_qs_mturk, -> { 
    left_outer_joins(:task)
    .select('MAX(results.id) as id', 'MAX(results.created_at) as created_at', 'count(*) as num_results', :project_id, :tweet_id, :task_id, 'tasks.mturk_batch_job_id as mturk_batch_job_id')
    .group(:project_id, :tweet_id, 'tasks.mturk_batch_job_id', :task_id)
  }
  # group by public user
  scope :group_by_qs, -> { 
    select('MAX(results.id) as id', 'MAX(results.created_at) as created_at', 'count(*) as num_results', :project_id, :tweet_id, :user_id)
    .group(:project_id, :tweet_id, :user_id)
  }

  enum res_type: [:public, :local, :mturk], _suffix: true
  enum flag: [:default, :incorrect, :correct], _prefix: true
  enum manual_review_status: [:unreviewed, :reviewed], _suffix: true

  private

  def update_worker_manual_review_status
    # as worker completes more work his review status is set back to false
    task&.mturk_worker&.update_attribute(:manually_reviewed, false)
  end
end
