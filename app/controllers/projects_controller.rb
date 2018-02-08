class ProjectsController < ApplicationController
  def index
    @projects = Project.all.where('public': true)
  end

  def show
    @project = Project.friendly.find(params[:id])
    raise 'This project has nothing to show' unless @project.es_index_name == 'project_vaccine_sentiment' 

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
