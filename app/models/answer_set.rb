class AnswerSet < ApplicationRecord
  for i in 0..9
    belongs_to eval(":answer"+i.to_s), class_name: 'Answer'
  end
  has_many :questions
end
