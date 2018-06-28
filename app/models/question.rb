class Question < ApplicationRecord
  belongs_to :project
  has_many :question_answers, dependent: :destroy
  has_many :answers, -> {order 'question_answers.order'}, through: :question_answers
  has_many :transitions
  has_many :results
end
