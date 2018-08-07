class AddSlugColumnToLocalBatchJobs < ActiveRecord::Migration[5.1]
  def change
    add_column :local_batch_jobs, :slug, :string
    add_index :local_batch_jobs, :slug
  end
end
