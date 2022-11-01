class MturkWorkerQualificationList < ApplicationRecord
  include CsvFileHandler

  has_one :primary_mturk_batch_job, inverse_of: :mturk_worker_qualification_list

  has_many :qualified_workers, dependent: :delete_all
  has_many :mturk_workers, through: :qualified_workers
  has_many :mturk_batch_jobs


  enum status: { default: 0, updating: 1, deleting: 2, failed: 3 }, _suffix: true

  validates :name, presence: true, uniqueness: { message: 'Name must be unique' }
  validates_with CsvValidator, fields: [:job_file]

  def create_qualification_type
    mturk = Mturk.new(sandbox: sandbox)
    props = {
      name: "QualificationList_#{name}",
      description: description,
      qualification_type_status: 'Active',
      auto_granted: true,
      auto_granted_value: 1
    }
    qual_type_id = mturk.create_qualification_type(props)
    update_attribute(:qualification_type_id, qual_type_id)
    qual_type_id
  end
end
