class AddFieldsToMturkBatchJob < ActiveRecord::Migration[5.1]
  def change
    add_column :mturk_batch_jobs, :description, :text
    add_column :mturk_batch_jobs, :title, :string
    add_column :mturk_batch_jobs, :keywords, :string
    add_column :mturk_batch_jobs, :reward, :decimal, precision: 8, scale: 2
    add_column :mturk_batch_jobs, :lifetime_in_seconds, :integer
    add_column :mturk_batch_jobs, :auto_approval_delay_in_seconds, :integer
    add_column :mturk_batch_jobs, :assignment_duration_in_seconds, :integer
  end
end
