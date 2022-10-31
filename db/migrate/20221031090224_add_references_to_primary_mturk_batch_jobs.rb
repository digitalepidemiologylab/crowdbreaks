class AddReferencesToPrimaryMturkBatchJobs < ActiveRecord::Migration[5.2]
  def change
    add_reference :primary_mturk_batch_jobs, :mturk_worker_qualification_list, foreign_key: true, index: {
      name: 'index_primary_mturk_batch_jobs_on_mturk_qualification_list_id'
    }
    # add_reference :mturk_worker_qualification_lists, :primary_mturk_batch_job, foreign_key: true, index: {
    #   name: 'index_mturk_qualification_lists_on_primary_mturk_batch_job_id'
    # }
    add_reference :primary_mturk_batch_jobs, :mturk_batch_job, foreign_key: true
  end
end
