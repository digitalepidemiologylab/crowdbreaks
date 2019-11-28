class AddExistingQualificationToMturkBatchJobs < ActiveRecord::Migration[5.2]
  def change
    add_column :mturk_batch_jobs, :existing_qualification_type_id, :string, default: '', null: false
  end
end
