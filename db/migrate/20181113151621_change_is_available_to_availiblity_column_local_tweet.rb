class ChangeIsAvailableToAvailiblityColumnLocalTweet < ActiveRecord::Migration[5.2]
  def up
    add_column :local_tweets, :availability, :integer, default: 0
    LocalTweet.all.each do |lt|
      if lt.is_available?
        lt.availability = 1
      else
        lt.availability = 2
      end
      lt.save
    end
    remove_column :local_tweets, :is_available
  end

  def down
    add_column :local_tweets, :is_available, :boolean, default: true
    LocalTweet.reset_column_information
    LocalTweet.all.each do |lt|
      if lt.availability == 2
        lt.is_available = false
      else
        lt.is_available = true
      end
      lt.save
    end
    remove_column :local_tweets, :availability
  end
end
