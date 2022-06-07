class AddAutoToLocalBatchJobs < ActiveRecord::Migration[5.2]
  def change
    add_column :local_batch_jobs, :auto, :boolean, null: false, default: false
  end
end
