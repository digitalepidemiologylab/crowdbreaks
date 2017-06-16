# == Schema Information
#
# Table name: answer_sets
#
#  id         :integer          not null, primary key
#  name       :string
#  answer0_id :integer
#  answer1_id :integer
#  answer2_id :integer
#  answer3_id :integer
#  answer4_id :integer
#  answer5_id :integer
#  answer6_id :integer
#  answer7_id :integer
#  answer8_id :integer
#  answer9_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class AnswerSet < ApplicationRecord
  (0..9).each do |i|
    belongs_to ('answer' + i.to_s).to_sym, class_name: 'Answer'
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
