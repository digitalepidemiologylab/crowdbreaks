class PrimaryMturkBatchJob < ApplicationRecord
  belongs_to :project
  has_one :mturk_batch_job

  validates :project, uniqueness: true
end
