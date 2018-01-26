class PagesController < ApplicationController
  def index
    @num_tweets_classified = Result.count
    @translations = I18n.backend.send(:translations)[I18n.locale][:pages][:index][:leadline]
  end

  def about
  end

  def privacy
  end

  def terms_of_use
  end
end
