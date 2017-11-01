class MturkBatchJob < ApplicationRecord
  has_many :tasks

  validates :name, presence: true, uniqueness: {message: "Name must be unique"}
end
