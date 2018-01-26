class ProjectsController < ApplicationController
  def index
    @projects = Project.all.where('public': true)
  end

  def show
    @project = Project.friendly.find(params[:id])
    raise 'This project has nothing to show' unless @project.es_index_name == 'project_vaccine_sentiment' 
    @interval = 'hour'
    @pro_vaccine_count = @project.results.joins(:answer).where(answers: {label: 'pro-vaccine'}).count
    @anti_vaccine_count = @project.results.joins(:answer).where(answers: {label: 'anti-vaccine'}).count
    @neutral_vaccine_count = @project.results.joins(:answer).where(answers: {label: 'neutral'}).count
    @total_count = @pro_vaccine_count + @anti_vaccine_count + @neutral_vaccine_count
  end

  private
  
end
