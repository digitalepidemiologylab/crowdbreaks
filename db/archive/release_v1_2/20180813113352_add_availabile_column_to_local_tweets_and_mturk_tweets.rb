class AddAvailabileColumnToLocalTweetsAndMturkTweets < ActiveRecord::Migration[5.1]
  def change
    add_column :local_tweets, :is_available, :boolean, default: true
    add_column :mturk_tweets, :is_available, :boolean, default: true
  end
end
