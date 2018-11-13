class ChangeIsAvailableToAvailiblityColumnMturkTweet < ActiveRecord::Migration[5.2]
  def up
    MturkTweet.all.each do |mt|
      if mt.is_available?
        mt.availability = 1
      else
        mt.availability = 2
      end
      mt.save
    end
    remove_column :mturk_tweets, :is_available
  end

  def down
    add_column :mturk_tweets, :is_available, :boolean, default: true
    MturkTweet.reset_column_information
    MturkTweet.all.each do |mt|
      if mt.availability == 2
        mt.is_available = false
      else
        mt.is_available = true
      end
      mt.save
    end
  end
end
