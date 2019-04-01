class AddAvailibilityToMturkTweet < ActiveRecord::Migration[5.2]
  def change
    add_column :mturk_tweets, :availability, :integer, :default => 0
  end
end
