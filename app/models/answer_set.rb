class AnswerSet < ApplicationRecord
  (0..9).each do |i|
    belongs_to eval(":answer" + i.to_s), class_name: 'Answer'
  end
  has_many :questions

  # get all answer_id's not nil
  def valid_answers
    valid_answers = []
    col_names = (0..9).map { |i| "answer" + i.to_s + "_id" }
    attributes.each_pair do |name, value|
      valid_answers.push(value) if col_names.include?(name) && value
    end
    valid_answers
  end
end
