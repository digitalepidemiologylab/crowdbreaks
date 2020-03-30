class ApisController < ApplicationController
  before_action :api_init

  def get_predictions
    authorize! :view, :ml
    options = {
      interval: api_params_predictions[:interval],
      start_date: api_params_predictions[:start_date],
      end_date: api_params_predictions[:end_date],
      include_retweets: api_params_predictions[:include_retweets],
    }
    es_index_name = api_params_predictions[:es_index_name]
    question_tag = api_params_predictions[:question_tag]
    answer_tags = api_params_predictions[:answer_tags]
    run_name = api_params_predictions[:run_name] || ''
    use_cache = api_params_predictions[:use_cache]
    average_label_val = api_params_predictions[:average_label_val].nil? ? false : true
    resp = {}
    resp['predictions'] = @api.get_predictions(es_index_name,
                                question_tag,
                                answer_tags,
                                run_name=run_name,
                                options=options,
                                use_cache=use_cache)
    if average_label_val
      resp['avg_label_vals'] = @api.get_avg_label_val(es_index_name, question_tag, run_name=run_name, options=options, use_cache=use_cache)
    else
      resp['avg_label_vals'] = []
    end
    render json: resp.to_json, status: 200
  end

  def endpoint_info
    model_endpoints = Project.where.not(model_endpoints: {}).pluck(:model_endpoints, :es_index_name)
    endpoint_info = {}
    model_endpoints.each do |endpoint, es_index_name|
      _project_endpoints = {}
      endpoint.each do |question_tag, question_tag_endpoints|
        resp = @api.endpoint_labels(question_tag_endpoints['primary'])
        if not resp['success'].nil? and not resp['success']
          render json: resp.to_json, status: resp['status']
        end
        _endpoints = []
        question_tag_endpoints['active'].each do |endpoint_name, endpoint_obj|
          is_primary = endpoint_name == question_tag_endpoints['primary']
          _endpoints.push({is_primary: is_primary, endpoint_name: endpoint_name, run_name: endpoint_obj['run_name']})
        end
        _project_endpoints[question_tag] = {endpoints: _endpoints, **resp.symbolize_keys}
      end
      endpoint_info[es_index_name] = _project_endpoints
    end
    render json: endpoint_info.to_json, status: 200
  end

  def update_sentiment_map
    authorize! :access, :sentiment_visualization
    options = {start_date: api_params_predictions[:start_date], end_date: api_params_predictions[:end_date]}
    if not api_params_predictions[:es_index_name].present?
      render json: {'errors': ['es_index_name needs to be present']}, status: 400
      return
    end

    resp = @api.get_geo_sentiment(options)
    render json: resp.to_json, status: 200
  end

  def get_stream_graph_data
    options = {
      interval: api_params_predictions[:interval],
      start_date: api_params_predictions[:start_date],
      end_date: api_params_predictions[:end_date],
      include_retweets: true
    }
    resp = @api.get_predictions(
      'project_vaccine_sentiment',
      'sentiment',
      ['positive', 'negative', 'neutral'],
      run_name='',
      options=options,
      use_cache=false)
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

  def predict_ml_models
    authorize! :view, :ml
    resp = @api.predict(text: api_params_ml_predict['text'], endpoint: api_params_ml_predict['endpoint'])
    render json: resp.to_json, status: 200
  end

  def list_ml_models
    authorize! :view, :ml
    models = @api.list_model_endpoints(use_cache: api_params_ml['use_cache'])
    resp = []
    models.each do |model|
      if model['Tags'].present?
        if model['Tags']['project_name'].present?
          project_name = model['Tags']['project_name']
          project = Project.by_name(project_name)
          next if project.nil?
          model_name = model['ModelName']
          question_tag = model['Tags']['question_tag']
          model['ActiveEndpoint'] = project.has_endpoint_for_question_tag(model_name, question_tag)
          model['IsPrimaryEndpoint'] = project.is_primary_endpoint_for_question_tag(model_name, question_tag)
          resp.push(model)
        end
      end
    end
    Project.where.not('model_endpoints': {}).each do |project|
      project.sync_endpoints_with_remote(resp)
    end
    render json: resp.to_json, status: 200
  end

  def update_ml_models
    authorize! :view, :ml
    action = api_params_ml_update['action']
    model_name = api_params_ml_update['model_name']
    project_name = api_params_ml_update['project_name']
    question_tag = api_params_ml_update['question_tag']
    model_type = api_params_ml_update['model_type']
    run_name = api_params_ml_update['run_name']
    project = Project.by_name(project_name)
    if project.nil?
      msg = "Project #{project_name} could not be found."
      render json: {message: msg}.to_json, status: 400 and return
    end
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
      if action == 'activate_endpoint'
        project.add_endpoint(model_name, question_tag, model_type, run_name)
        if project.has_endpoint_for_question_tag(model_name, question_tag)
          msg = 'Successfully activated endpoint. Restart stream for changes to be active.'
          render json: {message: msg}.to_json, status: 200 and return
        else
          msg = 'Something went wrong when trying to activate endpoint.'
          render json: {message: msg}.to_json, status: 400 and return
        end
      elsif action == 'deactivate_endpoint'
        project.remove_endpoint(model_name, question_tag)
        if not project.has_endpoint_for_question_tag(model_name, question_tag)
          msg = 'Successfully deactivated endpoint. Restart stream for changes to be active.'
          render json: {message: msg}.to_json, status: 200 and return
        else
          msg = 'Something went wrong when trying to deactivate endpoint.'
          render json: {message: msg}.to_json, status: 400 and return
        end
      elsif action == 'make_primary'
        project.make_primary_endpoint(model_name, question_tag)
        if project.is_primary_endpoint_for_question_tag(model_name, question_tag)
          msg = 'Successfully set endpoint as primary. Restart stream for changes to be active.'
          render json: {message: msg}.to_json, status: 200 and return
        else
          msg = 'Something went wrong when trying to set endpoint to primary.'
          render json: {message: msg}.to_json, status: 400 and return
        end
      else
        msg = "Update action #{action} is not known."
        render json: {message: msg}.to_json, status: 400 and return
      end
    end
  end

  def download_resource_info
    client = AwsS3.new(bucket: 'crowdbreaks-public')
    project = api_params_download_resource[:project]
    key = "data_dump/#{project}/data_dump_ids_#{project}.txt.gz"
    if not client.exists?(key)
      render json: {message: 'File does not exist.'}.to_json, status: 404 and return
    end
    resp = client.head(key)
    resp = {last_modified: resp['last_modified'], size: resp['content_length']}
    render json: resp.to_json, status: 200
  end

  private

  def api_params_user_activity
    params.require(:user_activity).permit(:start_date, :end_date)
  end

  def api_params
    params.require(:api).permit(:interval, :text, :change_stream_status, :es_index_name, :past_minutes)
  end

  def api_params_download_resource
    params.require(:download_resource).permit(:project)
  end

  def api_params_predictions
    params.require(:viz).permit(:interval, :start_date, :end_date, :es_index_name, :include_retweets, :question_tag, :use_cache, :run_name, :average_label_val, :answer_tags => [])
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

  def api_params_ml_predict
    params.require(:ml).permit(:text, :endpoint)
  end

  def api_params_ml_update
    params.require(:ml).permit(:action, :model_name, :project_name, :question_tag, :run_name, :model_type, :run_name)
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
