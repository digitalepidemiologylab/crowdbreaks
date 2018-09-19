class AddMaxTasksPerWorkerToMturkBatchJobs < ActiveRecord::Migration[5.1]
  def change
    add_column :mturk_batch_jobs, :max_tasks_per_worker, :integer, default: nil
  end
end
