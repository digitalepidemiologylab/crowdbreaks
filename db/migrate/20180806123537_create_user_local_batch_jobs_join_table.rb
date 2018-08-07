class CreateUserLocalBatchJobsJoinTable < ActiveRecord::Migration[5.1]
  def change
    create_join_table :users, :local_batch_jobs do |t|
      t.index :user_id
      t.index :local_batch_job_id
    end
  end
end
