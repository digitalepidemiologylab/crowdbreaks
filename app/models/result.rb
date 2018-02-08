class Result < ApplicationRecord
  belongs_to :question
  belongs_to :user
  belongs_to :answer
  belongs_to :project, counter_cache: true
  belongs_to :task, optional: true


  private
end
