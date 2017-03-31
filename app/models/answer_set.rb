class AnswerSet < ApplicationRecord
  for i in 0..9
    belongs_to eval(":answer"+i.to_s), class_name: 'Answer'
  end
  has_many :questions


  # get all answer_id's not nil
  def get_valid_answers
    valid_answers = []
    col_names = (0..9).map{|i| "answer"+i.to_s+"_id" }
    self.attributes.each_pair do |name, value|
      if col_names.include? name and value
        valid_answers.push(value)
      end
    end
    valid_answers
  end
end
