class AddMinimalApprovalRateToMturkBatchJob < ActiveRecord::Migration[5.1]
  def change
    add_column :mturk_batch_jobs, :minimal_approval_rate, :integer
  end
end
