class MoveHitTypeIdFromTasksToMturkBatchJobs < ActiveRecord::Migration[5.1]
  def change
    remove_column :tasks, :hittype_id, :string
    add_column :mturk_batch_jobs, :hittype_id, :string
  end
end
