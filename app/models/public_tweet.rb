class PublicTweet < ApplicationRecord
  belongs_to :project

  # Availibilty of tweet (if not_available tweet may be either protected or deleted)
  enum availability: [:unknown, :available, :unavailable]

  scope :not_assigned_to_user, -> (user_id, project_id) { where.not(tweet_id: Result.where({project_id: project_id, user_id: user_id}).select(:tweet_id))}
  scope :may_be_available, -> { where(availability: [:available, :unknown]) }
end
