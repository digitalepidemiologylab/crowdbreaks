class AddTweetsPerBatchToProjects < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :tweets_per_batch, :integer, default: nil
  end
end
