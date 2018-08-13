class MturkTweet < ApplicationRecord
  belongs_to :mturk_batch_job
  has_many :tasks
  has_many :mturk_workers, through: :tasks

  scope :unassigned, -> { includes(:tasks).where(tasks: {id: nil}) }
  scope :assigned, -> { includes(:tasks).where.not(tasks: {id: nil}) }
  scope :num_assignments_below, -> (threshold) { where(id: MturkTweet.select(:id).joins(:tasks).group('mturk_tweets.id').having('count(tasks.id) < ?', threshold)) }
  scope :not_assigned_to_worker, -> (worker_id) { MturkTweet.where.not(id: MturkWorker.find_by(worker_id: worker_id)&.mturk_tweets&.select(:id)) }
  scope :assigned_to_worker, -> (worker_id) { includes(:mturk_workers).where(mturk_workers: {worker_id: worker_id}) }
  scope :is_available, -> { where(is_available: true) }
  scope :is_unavailable, -> { where(is_available: false) }


  def set_to_unavailable
    update_attribute(:is_available, false)
  end
end
