class AddLocalBatchJobReferenceToResults < ActiveRecord::Migration[5.1]
  def change
    add_reference :results, :local_batch_job, index: true
  end
end
