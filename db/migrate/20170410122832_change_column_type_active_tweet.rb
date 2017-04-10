class ChangeColumnTypeActiveTweet < ActiveRecord::Migration[5.0]
  def self.up
    change_column :active_tweets, :tweet_id, :bigint
  end

  def self.down
    change_column :active_tweets, :tweet_id, :integer
  end
end
