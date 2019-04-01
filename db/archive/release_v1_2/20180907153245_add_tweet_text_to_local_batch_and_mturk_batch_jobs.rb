class AddTweetTextToLocalBatchAndMturkBatchJobs < ActiveRecord::Migration[5.1]
  def change
    add_column :mturk_tweets, :tweet_text, :text, default: ""
    add_column :local_tweets, :tweet_text, :text, default: ""
  end
end
