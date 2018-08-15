class Result < ApplicationRecord
  belongs_to :question
  belongs_to :user
  belongs_to :answer
  belongs_to :project, counter_cache: true
  belongs_to :task, optional: true
  belongs_to :local_batch_job, optional: true
  belongs_to :question_sequence_log, optional: true


  scope :counts_by_user, -> (user_id) {where(user_id: user_id).distinct.count(:tweet_id)}

  private
end
