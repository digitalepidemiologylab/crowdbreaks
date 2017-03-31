class Transition < ApplicationRecord
  belongs_to :from_question, class_name: 'Question'
  belongs_to :answer
  belongs_to :to_question, class_name: 'Question'
  belongs_to :project

end
