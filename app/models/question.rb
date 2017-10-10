class Question < ApplicationRecord
  belongs_to :project
  has_many :answer_sets, dependent: :destroy
  has_many :answers, through: :answer_sets 
  has_many :transitions
  has_many :results

  translates :question

  def display_name
    question
  end
end
