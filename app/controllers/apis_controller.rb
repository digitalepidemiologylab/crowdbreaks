class ApisController < ApplicationController
  before_action :api_init

  # Sentiment text box
  def vaccine_sentiment
    resp = @api.get_vaccine_sentiment(api_params[:text])
    render json: resp.parsed_response.to_json, status: 200
  end

  # Sentiment visualization
  def update_visualization
    options = {interval: api_params_viz[:interval], start_date: api_params_viz[:start_date], end_date: api_params_viz[:end_date]}
    if not api_params_viz[:es_index_name].present?
      render json: {'errors': ['es_index_name needs to be present']}, status: 400
      return
    end
    
    resp = {
      "all_data": @api.get_all_data(api_params_viz[:es_index_name], options),
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

  # end of question sequence
  def question_sequence_end
    project = Project.find_by(id: api_params_qs[:project_id]).es_index_name
    @api.update_tweet(project, api_params_qs[:user_id], api_params_qs[:tweet_id])
  end


  # front page leadline
  def get_leadline
    since = api_params_leadline.fetch(:since, 30.days.ago)
    exclude_tweet_ids = api_params_leadline.fetch(:exclude_tweet_ids, [])
    exclude_usernames = api_params_leadline.fetch(:exclude_usernames, [])
    num_new_entries = api_params_leadline.fetch(:num_new_entries, 3)

    result = []
    num_new_entries.to_i.times do
      resp = Result.order(created_at: :desc).where(created_at: since..Time.now).where.not(tweet_id: exclude_tweet_ids).
        joins(:user, :answer, :project).where(projects: {public: true}).where.not(users: {username: exclude_usernames}).where(answers: {label: Answer::LABELS.values}).limit(1).
        pluck('results.tweet_id,users.username as username,answers.label as label,results.created_at,projects.title_translations as title')
      result.push(resp[0])
      exclude_tweet_ids.push(resp[0][0].to_s) # distinct select doesn't work with order query, hence this approach
    end

    result.map!{|d| [d[0].to_s, *d[1..-1]]}  # convert to string before sending
    render json: result.to_json, status: 200
  end


  private
  
  def api_params
    params.require(:api).permit(:interval, :text, :change_stream_status, :es_index_name, :past_minutes)
  end

  def api_params_qs
    params.require(:qs).permit(:tweet_id, :user_id, :project_id)
  end

  def api_params_viz
    params.require(:viz).permit(:interval, :start_date, :end_date, :es_index_name)
  end

  def api_params_leadline
    params.require(:leadline).permit(:since, :num_new_entries, :exclude_tweet_ids => [], :exclude_usernames => [])
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
