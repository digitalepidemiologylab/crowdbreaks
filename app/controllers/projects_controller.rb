class ProjectsController < ApplicationController
  after_action :allow_cross_origin, only: [:show]

  def index
    @projects = Project.all
  end

  def show
    @project = Project.friendly.find(params[:id])
    raise 'This project has nothing to show' unless @project.es_index_name == 'project_vaccine_sentiment' 
  end


  private

  def allow_cross_origin
    response.headers.delete "X-Frame-Options"
  end
end
