class Result < ApplicationRecord
  belongs_to :question
  belongs_to :user
  belongs_to :answer
  belongs_to :project
  belongs_to :mturk_token
end
