class AddMturkAutoBatchToMturkBatchJob < ActiveRecord::Migration[5.2]
  def change
    add_reference :mturk_batch_jobs, :mturk_auto_batch, foreign_key: true
  end
end
