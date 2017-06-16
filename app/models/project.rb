# == Schema Information
#
# Table name: projects
#
#  id                       :integer          not null, primary key
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  title_translations       :jsonb
#  description_translations :jsonb
#  es_index_name            :string
#

class Project < ApplicationRecord
  has_many :questions
  has_many :transitions

  translates :title, :description

  validates_presence_of :title, :description

  def initial_question
    first_transition = transitions.find_by(from_question: nil)
    raise "Project #{self.title} does not have a valid first Question" if first_transition.nil?
    first_transition.to_question
  end
end
