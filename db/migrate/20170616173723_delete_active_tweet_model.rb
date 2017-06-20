class DeleteActiveTweetModel < ActiveRecord::Migration[5.0]
  def up
    drop_table :active_tweets
  end

  def down
    create_table :active_tweets do |t|
      t.bigint   "tweet_id"
      t.integer  "project_id"
      t.integer  "num_answers", default: 0
      t.float    "uncertainty", default: 1.0
      t.timestamps
    end
  end
end
