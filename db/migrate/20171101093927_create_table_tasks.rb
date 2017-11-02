class CreateTableTasks < ActiveRecord::Migration[5.1]
  def change
    create_table :tasks do |t|
      t.string :hit_id
      t.string :tweet_id
      t.string :assignment_id
      t.string :worker_id
      t.integer :lifecycle_status
      t.datetime :time_submitted
      t.datetime :time_completed
      t.references :mturk_batch_job
      t.timestamps
    end
  end
end
