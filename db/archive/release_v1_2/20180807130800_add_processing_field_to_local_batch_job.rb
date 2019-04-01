class AddProcessingFieldToLocalBatchJob < ActiveRecord::Migration[5.1]
  def change
    add_column :local_batch_jobs, :processing, :boolean, default: false
    add_column :local_batch_jobs, :deleting, :boolean, default: false
  end
end
