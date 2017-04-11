class Project < ApplicationRecord
  has_many :questions
  has_many :transitions
  has_many :active_tweets

  def initial_question
    transitions.find_by(from_question: nil)
  end
end
