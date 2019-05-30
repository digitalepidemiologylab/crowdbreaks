class PublicTweet < ApplicationRecord
  belongs_to :project

  # Availibilty of tweet (if not_available tweet may be either protected or deleted)
  enum availability: [:unknown, :available, :unavailable]

end
