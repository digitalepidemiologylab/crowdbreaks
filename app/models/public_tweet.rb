class PublicTweet < ApplicationRecord
  belongs_to :project

  # Availibilty of tweet (if not_available tweet may be either protected or deleted)
  enum availability: %i[unknown available unavailable]

  not_assigned_to_user = lambda do |user_id, project_id|
    where.not(tweet_id: Result.where({ project_id: project_id, user_id: user_id }).select(:tweet_id))
  end

  scope :not_assigned_to_user, not_assigned_to_user
  scope :may_be_available, -> { where(availability: %i[available unknown]) }

  scope :has_tweet_index, -> { where.not(tweet_index: [nil, '']) }
end
