class AddDisplayModeToLocalBatchJob < ActiveRecord::Migration[5.2]
  def change
    add_column :local_batch_jobs, :tweet_display_mode, :integer, default: 0, null: false
    add_index :local_batch_jobs, :tweet_display_mode
  end
end
