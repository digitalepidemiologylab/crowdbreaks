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


  def self.find_path_length(transitions)
    # Note: This gives the length of an arbitrary path from the start question 
    if not transitions.include?('start')
      return 0
    end
    len = 0
    current = transitions['start']
    while current.length > 0 do
      len += 1
      next_question = current[0][:to_question]
      current = transitions[next_question]
    end
    return len
  end
end
