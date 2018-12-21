class Result < ApplicationRecord
  belongs_to :question
  belongs_to :user
  belongs_to :answer
  belongs_to :project, counter_cache: true
  belongs_to :task, optional: true
  belongs_to :local_batch_job, optional: true
  belongs_to :question_sequence_log, optional: true

  scope :counts_by_user, -> (user_id) {where(user_id: user_id).distinct.count(:tweet_id)}
  scope :by_worker, -> (worker_id) { where(id: MturkWorker.find_by(worker_id: worker_id)&.results&.select(:id)) }
  scope :by_batch, -> (batch_name) { where(id: MturkBatchJob.find_by(name: batch_name)&.results&.select(:id)) }

  enum res_type: [:public, :local, :mturk], _suffix: true
  enum flag: [:default, :incorrect, :correct], _prefix: true

  private

end
