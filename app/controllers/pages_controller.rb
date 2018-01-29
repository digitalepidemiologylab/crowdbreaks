class PagesController < ApplicationController
  def index
    @num_tweets_classified = Result.distinct.count(:tweet_id)
    @translations = I18n.backend.send(:translations)[I18n.locale][:pages][:index][:leadline]
    if user_signed_in?
      @projects_contributed = current_user.results.pluck(:project_id).uniq
      query = current_user.results.joins(:project).where(projects: {es_index_name: 'project_vaccine_sentiment'})
      @pro_vaccine_count = query.joins(:answer).where(answers: {label: 'pro-vaccine'}).distinct.count(:tweet_id)
      @anti_vaccine_count = query.joins(:answer).where(answers: {label: 'anti-vaccine'}).distinct.count(:tweet_id)
      @neutral_vaccine_count = query.joins(:answer).where(answers: {label: 'neutral'}).distinct.count(:tweet_id)
      @total_count_vaccine_sentiment = @pro_vaccine_count + @anti_vaccine_count + @neutral_vaccine_count
      @total_count = current_user.results.distinct.count(:tweet_id)
      @vaccine_sentiment_project = Project.find_by(es_index_name: 'project_vaccine_sentiment')
    end
  end

  def about
  end

  def privacy
  end

  def terms_of_use
  end
end
