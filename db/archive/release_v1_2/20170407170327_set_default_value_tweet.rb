class SetDefaultValueTweet < ActiveRecord::Migration[5.0]
  def change
    change_column :tweets, :num_answers, :integer, :default => 0
    change_column :tweets, :uncertainty, :float, :default => 1
  end
end
