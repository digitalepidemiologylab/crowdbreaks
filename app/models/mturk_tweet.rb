class MturkTweet < ApplicationRecord
  has_many :mturk_worker_tweets, dependent: :destroy
  has_many :mturk_workers, through: :mturk_worker_tweets
end
