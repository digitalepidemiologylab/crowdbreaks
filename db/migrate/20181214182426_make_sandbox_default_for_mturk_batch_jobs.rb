class MakeSandboxDefaultForMturkBatchJobs < ActiveRecord::Migration[5.2]
  def up
    change_column :mturk_batch_jobs, :sandbox, :boolean, default: true
  end

  def down
    change_column :mturk_batch_jobs, :sandbox, :boolean, default: nil
  end
end
