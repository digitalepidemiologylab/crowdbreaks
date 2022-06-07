class CreatePrimaryMturkBatchJobs < ActiveRecord::Migration[5.2]
  def change
    create_table :primary_mturk_batch_jobs do |t|
      t.references :project, foreign_key: true, index: { unique: true }

      t.timestamps
    end
  end
end
