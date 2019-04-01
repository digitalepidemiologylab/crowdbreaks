class AddTestModeToLocalBatch < ActiveRecord::Migration[5.1]
  def change
    add_column :local_batch_jobs, :processing_mode, :integer, default: 0, null: false
  end
end
