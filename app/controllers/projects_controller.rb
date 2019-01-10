class ProjectsController < ApplicationController
  load_and_authorize_resource find_by: :slug

  def index
    # only select projects which are public and have to correct locale setting
    @projects = @projects.where(public: true).where("'#{I18n.locale.to_s}' = ANY (locales)")
  end

  def show
    if not @project.locales.include?(I18n.locale.to_s) or @project.es_index_name != 'project_vaccine_sentiment' 
      redirect_to projects_path
    end

    counts = @project.results.joins(:answer).group('answers.label').count
    if not counts.empty?
      @pro_vaccine_count = counts['pro-vaccine'] || 0
      @anti_vaccine_count = counts['anti-vaccine'] || 0
      @neutral_vaccine_count = counts['neutral'] || 0
    end
    @total_count = @pro_vaccine_count + @anti_vaccine_count + @neutral_vaccine_count
  end

  private
  
end
