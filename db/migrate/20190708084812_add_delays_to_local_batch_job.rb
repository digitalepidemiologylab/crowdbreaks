class AddDelaysToLocalBatchJob < ActiveRecord::Migration[5.2]
  def change
    add_column :local_batch_jobs, :delay_start, :integer, default: 2000, null: false
    add_column :local_batch_jobs, :delay_next_question, :integer, default: 1000, null: false
  end
end
