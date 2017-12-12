class ApisController < ApplicationController
  before_action :api_init

  # update stream configuration
  def set_config
    @projects = Project.all.where(active_stream: true)
    config = ActiveModelSerializers::SerializableResource.new(@projects).as_json
    resp = @api.set_config(config)
    if resp.success?
      respond_to do |format|
        flash[:notice] = resp.parsed_response
        format.html { redirect_to streaming_path }
      end
    else
      respond_to do |format|
        flash[:alert] = resp.parsed_response
        format.html { redirect_to streaming_path }
      end
    end
  end

  # Sentiment text box
  def vaccine_sentiment
    resp = @api.get_vaccine_sentiment(api_params[:text])
    render json: resp.parsed_response.to_json, status: 200
  end

  # Sentiment visualization
  def update_visualization
    options = {interval: api_params[:interval], start_date: '2017-06-01', end_date: '2017-06-21'}
    # options = {interval: params[:interval]}
    resp = {
      "all_data": @api.get_all_data(options),
      "pro_data": @api.get_sentiment_data('pro-vaccine', options),
      "anti_data": @api.get_sentiment_data('anti-vaccine', options),
      "neutral_data": @api.get_sentiment_data('neutral', options),
    }
    render json: resp.to_json, status: 200
  end


  private
  
  def api_params
    params.require(:api).permit(:interval, :text)
  end

  def api_init
    @api = FlaskApi.new
  end
end
