class RenameTweetTable < ActiveRecord::Migration[5.0]
  def change
    rename_table :tweets, :active_tweets
  end
end
