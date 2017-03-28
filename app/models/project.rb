class Project < ApplicationRecord
  has_many :questions
  has_many :transitions
end
