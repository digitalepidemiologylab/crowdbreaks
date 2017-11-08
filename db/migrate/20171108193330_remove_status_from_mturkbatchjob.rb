class RemoveStatusFromMturkbatchjob < ActiveRecord::Migration[5.1]
  def change
    remove_column :mturk_batch_jobs, :status, :integer, default: 0
  end
end
