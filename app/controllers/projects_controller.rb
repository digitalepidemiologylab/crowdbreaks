require 'flask_api'

class ProjectsController < ApplicationController
  after_action :allow_cross_origin, only: [:show, :vaccine_sentiment]

  def index
    @projects = Project.all
  end

  def show
    @project = Project.friendly.find(params[:id])
    raise 'This project has nothing to show' unless @project.es_index_name == 'project_vaccine_sentiment' 
  end

  def vaccine_sentiment
    api = FlaskApi.new
    resp = api.get_vaccine_sentiment(params[:text])
    render json: resp.parsed_response.to_json, status: 200
  end

  private

  def allow_cross_origin
    response.headers.delete "X-Frame-Options"
  end
end
