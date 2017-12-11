class ProjectsController < ApplicationController
  after_action :allow_cross_origin, only: [:show, :vaccine_sentiment]

  def index
    @projects = Project.all
  end

  def show
    @project = Project.friendly.find(params[:id])
    raise 'This project has nothing to show' unless @project.es_index_name == 'project_vaccine_sentiment' 
    api = FlaskApi.new
    options = {interval: 'hour', start_date: '2017-06-01', end_date: '2017-06-21'}
    # options = {interval: 'month'}
    @sent_viz_data = api.get_all_data(options)
    @sent_viz_pro = api.get_sentiment_data('pro-vaccine', options)
    @sent_viz_anti = api.get_sentiment_data('anti-vaccine', options)
    @sent_viz_neutral = api.get_sentiment_data('neutral', options)
  end

  def vaccine_sentiment
    api = FlaskApi.new
    resp = api.get_vaccine_sentiment(params[:text])
    render json: resp.parsed_response.to_json, status: 200
  end

  def update_visualization
    api = FlaskApi.new
    options = {interval: params[:interval], start_date: '2017-06-01', end_date: '2017-06-21'}
    # options = {interval: params[:interval]}
    resp = {
      "all_data": api.get_all_data(options),
      "pro_data": api.get_sentiment_data('pro-vaccine', options),
      "anti_data": api.get_sentiment_data('anti-vaccine', options),
      "neutral_data": api.get_sentiment_data('neutral', options),
    }
    render json: resp.to_json, status: 200
  end

  private
  
  def visualization_params
    params.require(:visualization).permit(:interval)
  end

  def allow_cross_origin
    response.headers.delete "X-Frame-Options"
  end
end
