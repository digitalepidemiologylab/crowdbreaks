class Project < ApplicationRecord
  has_many :questions
  has_many :transitions

  attr_reader :initial_question

  def initial_question
    transitions.find_by(:from_question => nil)
  end

end
