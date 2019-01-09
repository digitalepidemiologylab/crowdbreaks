class PagesController < ApplicationController
  authorize_resource :class => false

  def index
    @num_tweets_classified = Result.distinct.count(:tweet_id)
    if user_signed_in?
      # Project vaccine sentiment
      counts = current_user.results.joins(:project).where(projects: {es_index_name: 'project_vaccine_sentiment'}).joins(:answer).group('answers.label').count
      @pro_vaccine_count = counts['pro-vaccine'] || 0
      @anti_vaccine_count = counts['anti-vaccine'] || 0
      @neutral_vaccine_count = counts['neutral'] || 0
      @total_count_vaccine_sentiment = @pro_vaccine_count + @anti_vaccine_count + @neutral_vaccine_count
      @vaccine_sentiment_project = Project.find_by(es_index_name: 'project_vaccine_sentiment')
      @total_count = current_user.results.distinct.count(:tweet_id)
    end
  end

  def about
  end

  def privacy
  end

  def terms_of_use
  end
end
