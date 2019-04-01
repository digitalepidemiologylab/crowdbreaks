class CreateLocalTweets < ActiveRecord::Migration[5.1]
  def change
    create_table :local_tweets do |t|
      t.bigint :tweet_id
      t.references :local_batch_job
      t.timestamps
    end
  end
end
