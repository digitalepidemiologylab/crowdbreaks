class LocalTweet < ApplicationRecord
  belongs_to :local_batch_job

  scope :not_assigned_to_user, -> (user_id, batch_id) { where.not(tweet_id: Result.where({local_batch_job_id: batch_id, user_id: user_id}).select(:tweet_id))}
end
