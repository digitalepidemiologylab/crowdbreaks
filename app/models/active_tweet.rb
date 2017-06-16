# == Schema Information
#
# Table name: active_tweets
#
#  id          :integer          not null, primary key
#  tweet_id    :integer
#  project_id  :integer
#  num_answers :integer          default(0)
#  uncertainty :float            default(1.0)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class ActiveTweet < ApplicationRecord
  def self.initial_tweet
    # TODO: to be implemented... 
    # 847769197962723328
    # 847878099614171136
    # ActiveTweet.first(:order => "RANDOM()") 
    offset = rand(ActiveTweet.count)

    # Rails 4
    ActiveTweet.offset(offset).first.tweet_id

  end

end
