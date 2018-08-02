class ConnectWorkersThroughTasksToMturkTweet < ActiveRecord::Migration[5.1]
  def change
    remove_column :tasks, :tweet_id, :bigint
    remove_column :tasks, :worker_id, :string
    add_reference :tasks, :mturk_tweet, index: true
    add_reference :tasks, :mturk_worker, index: true
  end
end
