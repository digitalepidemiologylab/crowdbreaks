class CreateTableMturkTweets < ActiveRecord::Migration[5.1]
  def change
    create_table :mturk_tweets do |t|
      t.bigint :tweet_id
      t.references :mturk_batch_job
    end
  end
end
