# == Schema Information
#
# Table name: transitions
#
#  id                     :integer          not null, primary key
#  from_question_id       :integer
#  answer_id              :integer
#  to_question_id         :integer
#  project_id             :integer
#  transition_probability :float
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

class Transition < ApplicationRecord
  belongs_to :from_question, class_name: 'Question'
  belongs_to :answer
  belongs_to :to_question, class_name: 'Question'
  belongs_to :project

end
