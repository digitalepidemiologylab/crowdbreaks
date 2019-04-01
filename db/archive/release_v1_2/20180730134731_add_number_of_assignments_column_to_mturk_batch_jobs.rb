class AddNumberOfAssignmentsColumnToMturkBatchJobs < ActiveRecord::Migration[5.1]
  def change
    add_column :mturk_batch_jobs, :number_of_assignments, :integer, default: 1
  end
end
