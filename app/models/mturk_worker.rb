class MturkWorker < ApplicationRecord
  has_many :mturk_worker_tweets
  has_many :mturk_tweets, through: :mturk_worker_tweets, dependent: :destroy
end
