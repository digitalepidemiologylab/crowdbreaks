class LocalTweet < ApplicationRecord
  belongs_to :local_batch_job

  # Availibilty of tweet (if not_available tweet may be either protected or deleted)
  enum availability: [:unknown, :available, :unavailable]

  scope :not_assigned_to_user, -> (user_id, batch_id) { where.not(tweet_id: Result.where({local_batch_job_id: batch_id, user_id: user_id}).select(:tweet_id))}
  scope :may_be_available, -> { where(availability: [:available, :unknown]) }

  def done_by
    # list users who have worked on this tweet
    user_ids = local_batch_job.results.where(tweet_id: tweet_id).pluck(:user_id).uniq
    User.where(id: user_ids).pluck(:username)
  end
end
