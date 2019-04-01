class AddExcludeBlacklistedToMturkBatchJob < ActiveRecord::Migration[5.2]
  def change
    add_column :mturk_batch_jobs, :exclude_blacklisted, :boolean, default: true, null: false
  end
end
