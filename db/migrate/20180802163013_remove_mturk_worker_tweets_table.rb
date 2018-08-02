class RemoveMturkWorkerTweetsTable < ActiveRecord::Migration[5.1]
  def change
    drop_table :mturk_worker_tweets do |t|
      t.bigint "mturk_worker_id", null: false
      t.bigint "mturk_tweet_id", null: false
    end
  end
end
