# == Schema Information
#
# Table name: questions
#
#  id                    :integer          not null, primary key
#  project_id            :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  answer_set_id         :integer
#  question_translations :jsonb
#  meta_field            :string
#

class Question < ApplicationRecord
  belongs_to :project
  belongs_to :answer_set
  has_many :transitions

  translates :question

  def display_name
    question
  end
end
