class AddTimestampsToMturkTweet < ActiveRecord::Migration[5.2]
  def change
    add_timestamps :mturk_tweets, default: DateTime.now
    change_column_default :mturk_tweets, :created_at, nil
    change_column_default :mturk_tweets, :updated_at, nil
  end
end
