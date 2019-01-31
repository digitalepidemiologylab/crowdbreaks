class AddMinHitsQualificationToMturkBatchJobs < ActiveRecord::Migration[5.2]
  def change
    add_column :mturk_batch_jobs, :min_num_hits_approved, :integer
  end
end
