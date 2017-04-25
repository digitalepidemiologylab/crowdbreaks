class ActiveTweet < ApplicationRecord
  belongs_to :project

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
