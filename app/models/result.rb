# == Schema Information
#
# Table name: results
#
#  id          :integer          not null, primary key
#  question_id :integer
#  answer_id   :integer
#  user_id     :integer
#  project_id  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  tweet_id    :integer
#

class Result < ApplicationRecord
  belongs_to :question
  belongs_to :user
  belongs_to :answer
  belongs_to :project
end
