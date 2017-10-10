class Question < ApplicationRecord
  belongs_to :project
  has_many :question_answers, dependent: :destroy
  has_many :answers, through: :question_answers
  has_many :transitions
  has_many :results

  translates :question

  def display_name
    question
  end
end
