class CreateMturkBatchJobsTable < ActiveRecord::Migration[5.1]
  def change
    create_table :mturk_batch_jobs do |t|
      t.string :name
      t.string :status
      t.boolean :sandbox

      t.timestamps
    end
  end
end
