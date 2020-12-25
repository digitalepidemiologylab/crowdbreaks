class AddQualListReferenceToMturkBatchJobs < ActiveRecord::Migration[5.2]
  def change
    add_reference :mturk_batch_jobs, :mturk_worker_qualification_list, foreign_key: true
  end
end
