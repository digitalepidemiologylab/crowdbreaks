class AddMaxTasksPerWorkerToPrimaryMturkBatchJobs < ActiveRecord::Migration[5.2]
  def change
    add_column :primary_mturk_batch_jobs, :max_tasks_per_worker, :integer, null: false
  end
end
