class CreateJoinTableTweetsWorkers < ActiveRecord::Migration[5.1]
  def change
    create_join_table :mturk_workers, :mturk_tweets, table_name: 'mturk_worker_tweets'
  end
end
