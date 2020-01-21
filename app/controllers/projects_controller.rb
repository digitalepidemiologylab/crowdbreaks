class ProjectsController < ApplicationController
  load_and_authorize_resource find_by: :slug, except: [:viz]

  def index
    # only select projects which are public and have to correct locale setting
    @projects = @projects.order(created_at: :desc).where(public: true).where("'#{I18n.locale.to_s}' = ANY (locales)").accessible_by_user(current_user)
  end

  def show
    if not @project.public? or not @project.locales.include?(I18n.locale.to_s)
      redirect_to projects_path and return
    end

    if @project.es_index_name == 'project_vaccine_sentiment'
      counts = @project.results.joins(:answer).group('answers.label').count
      if not counts.empty?
        @pro_vaccine_count = counts['pro-vaccine'] || 0
        @anti_vaccine_count = counts['anti-vaccine'] || 0
        @neutral_vaccine_count = counts['neutral'] || 0
      end
      @total_count = @pro_vaccine_count + @anti_vaccine_count + @neutral_vaccine_count
    elsif @project.es_index_name == 'project_wuhan'
      # No setup for Wuhan project
    else
      redirect_to projects_path and return
    end
  end

  def viz
    @project = Project.find_by(es_index_name: 'project_vaccine_sentiment')
  end

  private

end
