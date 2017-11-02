class MturkBatchJob < ApplicationRecord
  has_many :tasks, dependent: :destroy
  belongs_to :project

  validates :name, presence: true, uniqueness: {message: "Name must be unique"}
  validates :job_file, presence: true
  validates :project, presence: true

  attr_accessor :job_file
  attr_accessor :number_of_assignments

  enum status: [:unsubmitted, :submitted, :completed]
  STATUS_LABELS = {
    unsubmitted: 'label-default',
    submitted: 'label-primary',
    completed: 'label-success'
  }




  private 

end
