class ApisController < ApplicationController
  before_action :api_init

  # Sentiment text box
  def vaccine_sentiment
    authorize! :access, :sentiment_visualization
    resp = @api.get_vaccine_sentiment(api_params[:text])
    render json: resp.parsed_response.to_json, status: 200
  end

  # Sentiment visualization
  def update_visualization
    authorize! :access, :sentiment_visualization
    options = {
      interval: api_params_viz[:interval],
      start_date: api_params_viz[:start_date],
      end_date: api_params_viz[:end_date],
      include_retweets: api_params_viz[:include_retweets]
    }
    if not api_params_viz[:es_index_name].present?
      render json: {'errors': ['es_index_name needs to be present']}, status: 400
      return
    end
    resp = {
      "all_data": @api.get_sentiment_data('*', options),
      "pro_data": @api.get_sentiment_data('pro-vaccine', options),
      "anti_data": @api.get_sentiment_data('anti-vaccine', options),
      "neutral_data": @api.get_sentiment_data('neutral', options),
      "avg_sentiment": @api.get_avg_sentiment(options)
    }
    render json: resp.to_json, status: 200
  end

  def update_sentiment_map
    authorize! :access, :sentiment_visualization
    options = {start_date: api_params_viz[:start_date], end_date: api_params_viz[:end_date]}
    if not api_params_viz[:es_index_name].present?
      render json: {'errors': ['es_index_name needs to be present']}, status: 400
      return
    end

    resp = @api.get_geo_sentiment(options)
    render json: resp.to_json, status: 200
  end

  def get_stream_graph_data
    options = {
      interval: api_params_viz[:interval],
      start_date: api_params_viz[:start_date],
      end_date: api_params_viz[:end_date],
    }
    resp = {
      "Pro-vaccine": @api.get_sentiment_data('pro-vaccine', options, use_cache=true),
      "Anti-vaccine": @api.get_sentiment_data('anti-vaccine', options, use_cache=true),
      "Neutral": @api.get_sentiment_data('neutral', options, use_cache=true),
    }
    render json: resp.to_json, status: 200
  end

  def get_stream_graph_keywords_data
    options = {
      interval: api_params_stream_graph_keywords[:interval],
      start_date: api_params_stream_graph_keywords[:start_date],
      end_date: api_params_stream_graph_keywords[:end_date]
    }
    query = api_params_stream_graph_keywords[:query]
    resp = {}
    if query.present?
      options[:keywords] = [query]
      resp[query] = @api.get_all_data(api_params_stream_graph_keywords[:es_index_name], options)
    else
      resp['__other'] = @api.get_all_data(api_params_stream_graph_keywords[:es_index_name], options)
    end
    render json: resp.to_json, status: 200
  end

  def get_trending_tweets
    options = {
      num_tweets: api_params_stream_graph_keywords[:num_trending_tweets],
      query: api_params_stream_graph_keywords[:query]
    }
    resp = @api.get_trending_tweets(api_params_stream_graph_keywords[:project_slug], options)
    render json: resp.to_json, status: 200
  end

  def get_trending_topics
    options = {
      num_topics: api_params_stream_graph_keywords[:num_trending_topics],
    }
    resp = @api.get_trending_topics(api_params_stream_graph_keywords[:project_slug], options)
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
    resp =  @api.get_all_data(api_params[:es_index_name], options, use_cache=false)
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
    @projects = Project.all.where(active_stream: true).where.not(es_index_name: nil)
    config = ActiveModelSerializers::SerializableResource.new(@projects).as_json
    resp = @api.set_config(config)
    respond_with_flash(resp, streaming_path, is_json: true)
  end

  # front page leadline
  def get_leadline
    since = api_params_leadline.fetch(:since, 30.days.ago)
    exclude_tweet_ids = api_params_leadline.fetch(:exclude_tweet_ids, [])
    exclude_usernames = api_params_leadline.fetch(:exclude_usernames, [])
    num_new_entries = api_params_leadline.fetch(:num_new_entries, 3)

    result = []
    num_new_entries.to_i.times do
      resp = Result.order(created_at: :desc).where(created_at: since..Time.current).where.not(tweet_id: exclude_tweet_ids).
        joins(:user, :answer, :project).where.not(users: {username: exclude_usernames}).limit(1).
        pluck(Arel.sql('results.tweet_id,users.username as username,answers.label as label,results.created_at,projects.title_translations as title'))
      unless resp.empty?
        if TweetValidation.new.tweet_is_valid?(resp[0][0])
          result.push(resp[0])
        end
        exclude_tweet_ids.push(resp[0][0].to_s) # distinct select doesn't work with order query, hence this approach
      end
    end

    result.map!{|d| [d[0].to_s, *d[1..-1]]}  # convert to string before sending
    render json: result.to_json, status: 200
  end

  def get_user_activity_data
    authorize! :access, :user_activity_data
    start_date = Time.parse(api_params_user_activity.fetch(:start_date, 30.days.ago.to_s))
    end_date = Time.parse(api_params_user_activity.fetch(:end_date, Time.current.to_s))
    counts = Result.where("created_at > ?", start_date).where("created_at < ?", end_date).group('created_at::date').count
    leaderboard = Result.where("results.created_at > ?", start_date).where("results.created_at < ?", end_date).joins(:user).group('users.email').count
    leaderboard = leaderboard.sort_by { |k, v| v }.reverse!.first(30)
    # Get username
    usernames = User.where(email: leaderboard.map(&:first)).pluck(:email, :username).to_h
    leaderboard.each_with_index do |item, i|
      item.push(usernames[item[0]])
    end
    render json: {'counts': counts, 'leaderboard': leaderboard}.to_json, status: 200
  end

  def list_ml_models
    authorize! :view, :ml
    models = @api.list_model_endpoints(use_cache: api_params_ml['use_cache'])
    resp = []
    models.each do |model|
      model['ActiveEndpoint'] = false
      if model['Tags'].present?
        if model['Tags']['project_name'].present?
          project_name = model['Tags']['project_name']
          model['ActiveEndpoint'] = Project.by_name(project_name).has_endpoint(model['ModelName'])
          resp.push(model)
        end
      end
    end
    render json: resp.to_json, status: 200
  end

  def update_ml_models
    authorize! :view, :ml
    action = api_params_ml_update['action']
    model_name = api_params_ml_update['model_name']
    project_name = api_params_ml_update['project_name']
    if action == 'create_endpoint'
      resp = @api.create_endpoint(model_name)
      if resp
        render json: {message: 'Endpoint successfully created'}.to_json, status: 200 and return
      else
        render json: {message: 'Something went wrong when creating endpoint'}.to_json, status: 400 and return
      end
    elsif action == 'delete_endpoint'
      resp = @api.delete_endpoint(model_name)
      if resp
        render json: {message: 'Endpoint successfully deleted'}.to_json, status: 200 and return
      else
        render json: {message: 'Something went wrong when deleting endpoint'}.to_json, status: 400 and return
      end
    elsif action == 'delete_model'
      resp = @api.delete_model(model_name)
      if resp
        render json: {message: 'Model successfully deleted'}.to_json, status: 200 and return
      else
        render json: {message: 'Something went wrong when deleting model'}.to_json, status: 400 and return
      end
    else
      project = Project.by_name(project_name)
      if project.nil?
        msg = "Project #{project_name} could not be found."
        render json: {message: msg}.to_json, status: 400 and return
      end
      if action == 'activate_endpoint'
        project.add_endpoint(model_name)
        if project.has_endpoint(model_name)
          msg = 'Successfully activated endpoint. Restart stream for changes to be active.'
          render json: {message: msg}.to_json, status: 200 and return
        else
          msg = 'Something went wrong when trying to activate endpoint.'
          render json: {message: msg}.to_json, status: 400 and return
        end
      elsif action == 'deactivate_endpoint'
        project.remove_endpoint(model_name)
        if not project.has_endpoint(model_name)
          msg = 'Successfully deactivated endpoint. Restart stream for changes to be active.'
          render json: {message: msg}.to_json, status: 200 and return
        else
          msg = 'Something went wrong when trying to deactivate endpoint.'
          render json: {message: msg}.to_json, status: 400 and return
        end
      else
        msg = "Update action #{action} is not known."
        render json: {message: msg}.to_json, status: 400 and return
      end
    end
  end

  private

  def api_params_user_activity
    params.require(:user_activity).permit(:start_date, :end_date)
  end

  def api_params
    params.require(:api).permit(:interval, :text, :change_stream_status, :es_index_name, :past_minutes)
  end

  def api_params_viz
    params.require(:viz).permit(:interval, :start_date, :end_date, :es_index_name, :include_retweets, :timeOption)
  end

  def api_params_stream_graph_keywords
    params.require(:viz).permit(:interval, :start_date, :end_date, :es_index_name, :timeOption, :query, :num_trending_tweets, :num_trending_topics, :project_slug)
  end

  def api_params_leadline
    params.require(:leadline).permit(:since, :num_new_entries, :exclude_tweet_ids => [], :exclude_usernames => [])
  end

  def api_params_ml
    params.require(:ml).permit(:use_cache)
  end

  def api_params_ml_update
    params.require(:ml).permit(:model_name, :action, :project_name)
  end

  def api_init
    @api = FlaskApi.new
  end

  def respond_with_flash(response, redirect_path, is_json: false)
    if is_json
      flash_notification = response.parsed_response['message']
    else
      flash_notification = response.parsed_response
    end
    if response.success?
      respond_to do |format|
        flash[:notice] = flash_notification
        format.html { redirect_to redirect_path }
      end
    else
      respond_to do |format|
        flash[:alert] = flash_notification
        format.html { redirect_to redirect_path }
      end
    end
  end
end
