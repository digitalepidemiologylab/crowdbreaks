class MturkTweet < ApplicationRecord
  has_many :tasks
  has_many :mturk_workers, through: :tasks
end
