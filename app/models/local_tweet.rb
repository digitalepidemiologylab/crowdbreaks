class LocalTweet < ApplicationRecord
  belongs_to :local_batch_job

  scope :not_assigned_to_user, -> (user_id, batch_id) { where.not(tweet_id: Result.where({local_batch_job_id: batch_id, user_id: user_id}).select(:tweet_id))}

  scope :is_available, -> { where(is_available: true) }
  scope :is_unavailable, -> { where(is_available: false) }


  def self.set_to_unavailable(tweet_id, local_batch_job_id)
    s = find_by(tweet_id: tweet_id, local_batch_job_id: local_batch_job_id)&.update_attribute(:is_available, false)
  end

  def done_by
    # list users who have worked on this tweet
    user_ids = local_batch_job.results.where(tweet_id: tweet_id).pluck(:user_id).uniq
    User.where(id: user_ids).pluck(:username)
  end
end
