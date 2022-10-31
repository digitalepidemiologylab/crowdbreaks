class PrimaryMturkBatchJob < ApplicationRecord
  belongs_to :project
  has_one :mturk_batch_job
  has_one :mturk_worker_qualification_list

  validates :project, uniqueness: true
end
