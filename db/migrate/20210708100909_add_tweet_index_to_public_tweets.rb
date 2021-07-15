class AddTweetIndexToPublicTweets < ActiveRecord::Migration[5.2]
  def change
    add_column :public_tweets, :tweet_index, :text, default: ''
  end
end
