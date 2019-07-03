class AddCheckAvailabilityToLocalBatchJobs < ActiveRecord::Migration[5.2]
  def change
    add_column :local_batch_jobs, :check_availability, :integer, default: 0, null: false
    add_index :local_batch_jobs, :check_availability
  end
end
