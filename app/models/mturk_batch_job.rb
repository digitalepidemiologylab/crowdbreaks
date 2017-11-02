class MturkBatchJob < ApplicationRecord
  has_many :tasks, dependent: :destroy
  attr_accessor :job_file
  attr_accessor :number_of_assignments


  validates :name, presence: true, uniqueness: {message: "Name must be unique"}
  validates :job_file, presence: true

  private 

end
