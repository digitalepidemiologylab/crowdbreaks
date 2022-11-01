class PrimaryMturkBatchJob < ApplicationRecord
  belongs_to :project
  belongs_to :mturk_batch_job, inverse_of: :primary_mturk_batch_job
  belongs_to :mturk_worker_qualification_list, inverse_of: :primary_mturk_batch_job

  validates :project, uniqueness: true
end
