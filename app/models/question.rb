class Question < ApplicationRecord
  belongs_to :project
  belongs_to :answer_set
  has_many :transitions


  def display_name
    question
  end

end
