class AddReferencesToMturkWorkerQualificationLists < ActiveRecord::Migration[5.2]
  def change
    add_reference :mturk_worker_qualification_lists, :primary_mturk_batch_job, foreign_key: true, index: {
      name: 'index_mturk_qualification_lists_on_primary_mturk_batch_job_id'
    }
  end
end
