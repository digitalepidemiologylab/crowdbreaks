class MturkTweet < ApplicationRecord
  has_many :mturk_worker_tweets
  has_many :mturk_workers, through: :mturk_worker_tweets, dependent: :destroy
end
