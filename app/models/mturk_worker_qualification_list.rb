class MturkWorkerQualificationList < ApplicationRecord
  include CsvFileHandler
  has_many :qualified_workers, dependent: :delete_all
  has_many :mturk_workers, through: :qualified_workers

  enum status: {default: 0, updating: 1, deleting: 2}, _suffix: true

  validates :name, presence: true, uniqueness: {message: "Name must be unique"}
  validates_with CsvValidator, fields: [:job_file]
end
