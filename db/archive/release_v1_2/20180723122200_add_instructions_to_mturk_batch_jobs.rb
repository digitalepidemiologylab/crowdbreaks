class AddInstructionsToMturkBatchJobs < ActiveRecord::Migration[5.1]
  def change
    add_column :mturk_batch_jobs, :instructions, :text, default: ""
  end
end
