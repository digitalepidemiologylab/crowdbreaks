class Question < ApplicationRecord
  belongs_to :project
  belongs_to :answer_set
end
