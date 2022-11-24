class AddS3FilenamesToMturkAutoBatches < ActiveRecord::Migration[5.2]
  def change
    add_column :mturk_auto_batches, :sample_s3_key, :string, default: nil
    add_column :mturk_auto_batches, :subsample_s3_key, :string, default: nil
  end
end
