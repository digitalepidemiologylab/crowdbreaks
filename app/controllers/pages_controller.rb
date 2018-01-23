class PagesController < ApplicationController
  def index
    @num_tweets_classified = Result.count
  end

  def about
  end
end
