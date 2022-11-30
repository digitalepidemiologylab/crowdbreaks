class AddS3FilenamesToRespectiveTables < ActiveRecord::Migration[5.2]
  def change
    add_column :mturk_batch_jobs, :sample_s3_key, :string, default: nil
    add_column :local_batch_jobs, :subsample_s3_key, :string, default: nil
  end
end
