class Project < ApplicationRecord
  has_many :questions
  has_many :transitions

  attr_accessor :initial_question

  def initial_question
    self.transitions.find_by(:from_question => nil)
  end

end
