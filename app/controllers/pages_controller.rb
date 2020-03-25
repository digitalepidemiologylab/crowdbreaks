class PagesController < ApplicationController
  authorize_resource :class => false

  def index
    @num_tweets_classified = Result.num_annotations
    if user_signed_in?
      @projects = Project.where(id: current_user.results.select('project_id').group('project_id').pluck(:project_id)).where(public: true).for_current_locale
      @counts = {}
      @projects.each do |project|
        label_counts = current_user.results.where(project_id: project.id).joins(:answer).group('answers.label').count
        @counts[project.id] = {
          'pro-vaccine': label_counts['pro-vaccine'] || 0,
          'anti-vaccine': label_counts['anti-vaccine'] || 0,
          'neutral': label_counts['neutral'] || 0,
        }
        @counts[project.id][:total] = @counts[project.id][:'pro-vaccine'] + @counts[project.id][:'anti-vaccine'] + @counts[project.id][:neutral]
      end
      @local_batch_jobs = current_user.local_batch_jobs
      @total_count = current_user.results.num_annotations
    end
  end

  def about
  end

  def data_sharing
    @projects = Project.order(created_at: :desc).where(public: true).where("'#{I18n.locale.to_s}' = ANY (locales)").accessible_by_user(current_user)
  end

  def privacy
  end

  def terms_of_use
  end
end
