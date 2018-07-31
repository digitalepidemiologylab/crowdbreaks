class AddMarkedForDeletionFieldToMturkBatchJobs < ActiveRecord::Migration[5.1]
  def change
    add_column :mturk_batch_jobs, :marked_for_deletion, :boolean, default: false
    add_column :mturk_batch_jobs, :processing, :boolean, default: false
  end
end
