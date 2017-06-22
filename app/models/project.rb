class Project < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: :slugged
  has_many :questions
  has_many :transitions
  has_many :results

  translates :title, :description

  validates_presence_of :title, :description

  def initial_question
    first_transition = transitions.find_by(from_question: nil)
    raise "Project #{self.title} does not have a valid first Question" if first_transition.nil?
    first_transition.to_question
  end
end
