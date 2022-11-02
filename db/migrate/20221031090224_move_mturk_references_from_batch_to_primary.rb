class MoveMturkReferencesFromBatchToPrimary < ActiveRecord::Migration[5.2]
  def change
    add_reference :primary_mturk_batch_jobs, :mturk_worker_qualification_list, foreign_key: true, index: {
      name: 'index_primary_mturk_batch_jobs_on_mturk_qualification_list_id'
    }

    reversible do |dir|
      dir.up do
        add_reference(:primary_mturk_batch_jobs, :mturk_batch_job, foreign_key: true)
        remove_column(:mturk_batch_jobs, :primary_mturk_batch_job_id)
      end
      dir.down do
        add_reference(:mturk_batch_jobs, :primary_mturk_batch_job, foreign_key: true)
        remove_column(:primary_mturk_batch_jobs, :mturk_batch_job_id)
      end
    end
  end
end
