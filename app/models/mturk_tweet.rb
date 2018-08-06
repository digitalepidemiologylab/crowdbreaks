class MturkTweet < ApplicationRecord
  belongs_to :mturk_batch_job
  has_many :tasks
  has_many :mturk_workers, through: :tasks

  scope :unassigned, -> { includes(:tasks).where(tasks: {id: nil}) }
  scope :assigned, -> { includes(:tasks).where.not(tasks: {id: nil}) }
  scope :num_assignments_below, -> (threshold) { joins(:tasks).group('mturk_tweets.id').having("count(tasks.mturk_tweet_id) < #{threshold}") }
  scope :not_assigned_to_worker, -> (worker_id) { joins(:mturk_workers).where.not(:mturk_workers => {worker_id: worker_id}) }
  scope :assigned_to_worker, -> (worker_id) { joins(:mturk_workers).where(:mturk_workers => {worker_id: worker_id}) }
end
