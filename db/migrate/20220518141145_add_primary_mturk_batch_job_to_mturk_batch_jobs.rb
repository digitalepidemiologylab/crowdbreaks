class AddPrimaryMturkBatchJobToMturkBatchJobs < ActiveRecord::Migration[5.2]
  def change
    add_reference :mturk_batch_jobs, :primary_mturk_batch_job, foreign_key: true
  end
end
