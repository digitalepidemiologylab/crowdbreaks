class ApisController < ApplicationController
  before_action :api_init

  # Sentiment text box
  def vaccine_sentiment
    resp = @api.get_vaccine_sentiment(api_params[:text])
    render json: resp.parsed_response.to_json, status: 200
  end

  # Sentiment visualization
  def update_visualization
    options = {interval: api_params[:interval], start_date: '2017-06-01 00:00:00', end_date: '2017-06-21 00:00:00'}
    if not api_params[:es_index_name].present?
      render json: {'errors': ['es_index_name needs to be present']}, status: 400
      return
    end
    
    resp = {
      "all_data": @api.get_all_data(api_params[:es_index_name], options),
      "pro_data": @api.get_sentiment_data('pro-vaccine', options),
      "anti_data": @api.get_sentiment_data('anti-vaccine', options),
      "neutral_data": @api.get_sentiment_data('neutral', options),
    }
    render json: resp.to_json, status: 200
  end


  # Monitor streams
  def stream_data
    authorize! :configure, :stream
    if not api_params[:es_index_name].present?
      render json: {'errors': ['es_index_name needs to be present']}, status: 400
      return
    end
    past_minutes = api_params.fetch(:past_minutes, 30)
    options = {interval: api_params[:interval], start_date: "now-#{past_minutes}m", end_date: 'now'}
    resp =  @api.get_all_data(api_params[:es_index_name], options)
    render json: resp.to_json, status: 200
  end

  # Change stream status
  def stream_status
    authorize! :configure, :stream

    case api_params[:change_stream_status]
    when 'start'
      resp = @api.start_streaming
      respond_with_flash(resp, streaming_path)
    when 'restart'
      resp = @api.restart_streaming
      respond_with_flash(resp, streaming_path)
    when 'stop'
      resp = @api.stop_streaming
      respond_with_flash(resp, streaming_path)
    end
  end
  
  # update stream configuration
  def set_config
    authorize! :configure, :stream

    @projects = Project.all.where(active_stream: true)
    config = ActiveModelSerializers::SerializableResource.new(@projects).as_json
    resp = @api.set_config(config)
    respond_with_flash(resp, streaming_path)
  end


  private
  
  def api_params
    params.require(:api).permit(:interval, :text, :change_stream_status, :es_index_name, :past_minutes)
  end

  def api_init
    @api = FlaskApi.new
  end

  def respond_with_flash(response, redirect_path)
    if response.success?
      respond_to do |format|
        flash[:notice] = response.parsed_response
        format.html { redirect_to redirect_path }
      end
    else
      respond_to do |format|
        flash[:alert] = response.parsed_response
        format.html { redirect_to redirect_path }
      end
    end
  end
end
