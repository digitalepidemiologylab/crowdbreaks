class PagesController < ApplicationController
  def index
    @num_tweets_classified = Result.count
  end

  def about
  end

  def privacy
  end

  def terms_of_use
  end
end
