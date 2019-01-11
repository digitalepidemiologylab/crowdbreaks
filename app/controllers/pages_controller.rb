class PagesController < ApplicationController
  authorize_resource :class => false

  def index
    @num_tweets_classified = Result.distinct.count(:tweet_id)
    if user_signed_in?
      @projects = Project.where(id: current_user.results.select('project_id').group('project_id').pluck(:project_id)).where(public: true).for_current_locale
      @counts = {}
      @projects.each do |project|
        label_counts = current_user.results.where(project_id: project.id).joins(:answer).group('answers.label').count
        @counts[project.id] = {
          'pro-vaccine': label_counts['pro-vaccine'] || 0,
          'anti-vaccine': label_counts['anti-vaccine'] || 0,
          'neutral': label_counts['pro-vaccine'] || 0,
          'pro-vaccine': label_counts['neutral'] || 0,
        }
        @counts[project.id][:total] = @counts[project.id][:'pro-vaccine'] + @counts[project.id][:'anti-vaccine'] + @counts[project.id][:neutral] 
      end
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
