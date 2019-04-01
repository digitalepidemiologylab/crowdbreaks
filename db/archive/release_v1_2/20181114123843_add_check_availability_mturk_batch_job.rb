class AddCheckAvailabilityMturkBatchJob < ActiveRecord::Migration[5.2]
  def change
    add_column :mturk_batch_jobs, :check_availability, :integer, default: 0
  end
end
