class ApisController < ApplicationController
  before_action :api_init

  # update stream configuration
  def set_config
    authorize! :configure, :stream

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

  private
  
  def api_params
    params.require(:api).permit(:interval, :text, :change_stream_status)
  end

  def api_init
    @api = FlaskApi.new
  end


  def respond_with_flash(response, redirect_path)
    if response.success?
      respond_to do |format|
        flash[:notice] = response.parsed_response
        format.html { redirect_to streaming_path }
      end
    else
      respond_to do |format|
        flash[:alert] = response.parsed_response
        format.html { redirect_to streaming_path }
      end
    end
  end

end
