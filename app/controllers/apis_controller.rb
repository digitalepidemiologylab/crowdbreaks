class ApisController < ApplicationController
  include Response
  before_action :api_init

  def get_predictions
    authorize! :view, :ml
    options = {
      interval: api_params_predictions[:interval],
      start_date: api_params_predictions[:start_date],
      end_date: api_params_predictions[:end_date],
      include_retweets: api_params_predictions[:include_retweets]
    }
    es_index_name = api_params_predictions[:es_index_name]
    question_tag = api_params_predictions[:question_tag]
    answer_tags = api_params_predictions[:answer_tags]
    run_name = api_params_predictions[:run_name]
    use_cache = api_params_predictions[:use_cache]
    average_label_val = api_params_predictions[:average_label_val].nil? ? false : true

    response = {}
    predictions_response = @api.get_predictions(
      index: es_index_name,
      question_tag: question_tag,
      answer_tags: answer_tags,
      run_name: run_name,
      use_cache: true,
      **options
    )
    response['predictions'] = predictions_response.success? ? predictions_response.body : {}

    if average_label_val
      avg_label_vals_response = @api.get_avg_label_val(
        index: es_index_name,
        question_tag: question_tag,
        run_name: run_name,
        use_cache: use_cache,
        **options
      )
      response['avg_label_vals'] = avg_label_vals_response.success? ? avg_label_vals_response.body : []
    end

    render json: response.to_json, status: 200
  end

  def endpoint_info
    model_endpoints = Project.where.not(model_endpoints: {}).pluck(:model_endpoints, :es_index_name)
    Rails.logger.info "Model endpoints: #{model_endpoints}"
    endpoint_info = {}
    model_endpoints.each do |endpoint, es_index_name|
      project_endpoints_ = {}
      endpoint.each do |question_tag, question_tag_endpoints|
        response = @api.endpoint_labels(question_tag_endpoints['primary'])
        Rails.logger.info response
        render json: { message: response.message }, status: 400 and return if response.error?

        endpoints_ = []
        question_tag_endpoints['active'].each do |endpoint_name, endpoint_obj|
          is_primary = endpoint_name == question_tag_endpoints['primary']
          endpoints_.push({ is_primary: is_primary, endpoint_name: endpoint_name, run_name: endpoint_obj['run_name'] })
        end
        project_endpoints_[question_tag] = { endpoints: endpoints_, **response.body }
      end
      endpoint_info[es_index_name] = project_endpoints_
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
    if resp.has_key?('success') and not resp['success']
      render json: resp.to_json, status: resp['status']
    else
      render json: resp.to_json, status: 200
    end
  end

  def get_stream_graph_keywords_data
    # TODO: Update for the new AwsApi.get_all_data
    options = {
      interval: Helpers::TimeParser.new(api_params_stream_graph_keywords[:interval]).time,
      start_date: api_params_stream_graph_keywords[:start_date],
      end_date: api_params_stream_graph_keywords[:end_date],
      round_to_sec: api_params_stream_graph_keywords[:round_to_sec].to_i
    }
    query = api_params_stream_graph_keywords[:query]
    resp = {}
    if query.present?
      options[:keywords] = [query]
    end
    _resp = @api.get_all_data(
      index: api_params_stream_graph_keywords[:es_index_name], **options
    )
    if _resp.is_a?(Hash) and _resp.has_key?('success') and not _resp['success']
      render json: _resp.to_json, status: _resp['status'] and return
    else
      if query.present?
        resp[query] = _resp
      else
        resp['__other'] = _resp
      end
    end
    render json: resp.to_json, status: 200
  end

  def get_trending_tweets
    # TODO: Check the response format and render it correctly
    resp = @api.get_trending_tweets(
      index: api_params_stream_graph_keywords[:es_index_name],
      size: api_params_stream_graph_keywords[:num_trending_tweets],
      term: api_params_stream_graph_keywords[:query]
    )
    if resp.is_a?(Hash) and resp.has_key?('success') and not resp['success']
      render json: resp.to_json, status: resp['status'] and return
    else
      render json: resp.to_json, status: 200
    end
  end

  def get_trending_topics
    # TODO: Check the response format and render it correctly
    resp = @api.get_trending_topics(
      slug: api_params_stream_graph_keywords[:project_slug],
      num_topics: api_params_stream_graph_keywords[:num_trending_topics]
    )
    if resp.is_a?(Hash) and resp.has_key?('success') and not resp['success']
      render json: resp.to_json, status: resp['status'] and return
    else
      render json: resp.to_json, status: 200
    end
  end

  # Monitor streams
  def stream_data
    authorize! :configure, :stream
    unless api_params[:es_index_name].present?
      render json: { 'errors': ['es_index_name needs to be present'] }, status: 400
      return
    end
    Rails.logger.info "API params round_to_sec: #{api_params[:round_to_sec]}"
    resp = @api.get_all_data(
      index: api_params[:es_index_name], interval: api_params[:interval],
      start_date: "now-#{api_params[:past_minutes]}m", end_date: 'now', round_to_sec: api_params[:round_to_sec].to_i
    )
    render json: resp.body.to_json, status: 200
  end

  # Change stream status
  def stream_status
    authorize! :configure, :stream
    quick_response = lambda do |action|
      Helpers::ApiResponse.new(
        status: :success, message: "Successfully sent a request to #{action} the streamer. Wait a minute please."
      )
    end

    case api_params[:change_stream_status]
    when 'start'
      StartStreamerJob.perform_later
      respond_with_flash(quick_response.call('start'), streaming_path)
    when 'restart'
      RestartStreamerJob.perform_later
      respond_with_flash(quick_response.call('restart'), streaming_path)
    when 'stop'
      StopStreamerJob.perform_later
      respond_with_flash(quick_response.call('stop'), streaming_path)
    end
  end

  # update stream configuration
  def upload_config
    authorize! :configure, :stream
    @projects = Project.primary.where(active_stream: true)
    selected_params = %i[keywords lang locales es_index_name slug active storage_mode image_storage_mode model_endpoints]
    config = @projects.to_json(only: selected_params)
    respond_with_flash(@api.upload_config(config), streaming_path)
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
        if TweetValidation.tweet_is_valid?(resp[0][0])
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
    counts = Result.public_res_type.where("created_at > ?", start_date).where("created_at < ?", end_date).group('created_at::date').count
    leaderboard = Result.public_res_type.where("results.created_at > ?", start_date).where("results.created_at < ?", end_date).joins(:user).group('users.email').count
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
    response = @api.predict(text: api_params_ml_predict['text'], endpoint_name: api_params_ml_predict['endpoint'])
    render json: response.body, status: 200 and return if response.success?

    render json: '{}', status: 200
  end

  def list_ml_models
    authorize! :view, :ml
    models_response = @api.list_model_endpoints(use_cache: api_params_ml[:use_cache])
    if models_response.error?
      render json: { message: models_response.message }.to_json, status: 400 and return
    end

    models = models_response.body
    response = []
    models.each do |model|
      puts model.class
      next if model.fetch(:tags, nil)&.fetch(:project_name, nil).nil?

      project_name = model[:tags][:project_name]
      project = Project.primary_project_by_name(project_name) #[8..-1]
      next if project.nil?

      model_name = model[:model_name]
      question_tag = model[:tags][:question_tag]
      model[:active_endpoint] = project.endpoint_for_question_tag?(model_name, question_tag)
      model[:is_primary_endpoint] = project.primary_endpoint_for_question_tag?(model_name, question_tag)
      response << model
    end
    Project.where.not('model_endpoints': {}).each do |project|
      project.sync_endpoints_with_remote(response)
    end
    render json: response.to_json, status: 200
  end

  def update_ml_models
    authorize! :view, :ml
    action = api_params_ml_update[:action]
    model_name = api_params_ml_update[:model_name]
    project_name = api_params_ml_update[:project_name]
    question_tag = api_params_ml_update[:question_tag]
    model_type = api_params_ml_update[:model_type]
    run_name = api_params_ml_update[:run_name]
    project = Project.primary_project_by_name(project_name) #[8..-1]
    if project.nil?
      msg = "Project #{project_name} could not be found."
      render json: { message: msg }.to_json, status: 400 and return
    end
    # Flash notifications are rendered in MlModels.js
    case action
    when 'create_endpoint'
      resp = @api.create_endpoint(model_name)
      render json: { message: 'Endpoint successfully created.' }.to_json, status: 200 and return if resp.success?

      render json: { message: 'Something went wrong when creating endpoint.' }.to_json, status: 400 and return
    when 'delete_endpoint'
      resp = @api.delete_endpoint(model_name)
      render json: { message: 'Endpoint successfully deleted.' }.to_json, status: 200 and return if resp.success?

      render json: { message: 'Something went wrong when deleting endpoint.' }.to_json, status: 400 and return
    when 'delete_model'
      resp = @api.delete_model(model_name)
      render json: { message: 'Model successfully deleted.' }.to_json, status: 200 and return if resp.success?

      render json: { message: 'Something went wrong when deleting model.' }.to_json, status: 400 and return
    when 'activate_endpoint'
      project.add_endpoint(model_name, question_tag, model_type, run_name)
      if project.endpoint_for_question_tag?(model_name, question_tag)
        msg = 'Successfully activated endpoint. Restart stream for changes to be active.'
        render json: { message: msg }.to_json, status: 200 and return
      else
        msg = 'Something went wrong when trying to activate endpoint.'
        render json: { message: msg }.to_json, status: 400 and return
      end
    when 'deactivate_endpoint'
      project.remove_endpoint(model_name, question_tag)
      if project.endpoint_for_question_tag?(model_name, question_tag)
        msg = 'Something went wrong when trying to deactivate endpoint.'
        render json: { message: msg }.to_json, status: 400 and return
      else
        msg = 'Successfully deactivated endpoint. Restart stream for changes to be active.'
        render json: { message: msg }.to_json, status: 200 and return
      end
    when 'make_primary'
      project.make_primary_endpoint(model_name, question_tag)
      if project.primary_endpoint_for_question_tag?(model_name, question_tag)
        msg = 'Successfully set endpoint as primary. Restart stream for changes to be active.'
        render json: { message: msg }.to_json, status: 200 and return
      else
        msg = 'Something went wrong when trying to set endpoint to primary.'
        render json: { message: msg }.to_json, status: 400 and return
      end
    else
      msg = "Update action #{action} is not known."
      render json: { message: msg }.to_json, status: 400 and return
    end
  end

  def download_resource_info
    client = AwsS3.new(bucket: 'crowdbreaks-public')
    project = api_params_download_resource[:project]
    modes = [
      { name: 'all', prefix: '' },
      { name: 'place', prefix: '_has_place' },
      { name: 'coordinates', prefix: '_has_coordinates' }
    ]
    resp = {}
    modes.each do |mode|
      name = mode[:name]
      resp[name] = { exists: false }
      key = "data_dump/#{project}/data_dump_ids_#{project}#{mode[:prefix]}.txt.gz"
      if client.exists?(key)
        resp[name][:exists] = true
        _resp = client.head(key)
        resp[name] = { **resp[name], last_modified: _resp['last_modified'], size: _resp['content_length'] }
      end
    end
    render json: resp.to_json, status: 200
  end

  private

  def api_params_user_activity
    params.require(:user_activity).permit(:start_date, :end_date)
  end

  def api_params
    params.require(:api).permit(:interval, :text, :change_stream_status, :es_index_name, :past_minutes, :round_to_sec)
  end

  def api_params_download_resource
    params.require(:download_resource).permit(:project)
  end

  def api_params_predictions
    params.require(:viz).permit(:interval, :start_date, :end_date, :es_index_name, :include_retweets, :question_tag, :use_cache, :run_name, :average_label_val, :answer_tags => [])
  end

  def api_params_stream_graph_keywords
    params.require(:viz).permit(:interval, :start_date, :end_date, :es_index_name, :timeOption, :query, :num_trending_tweets, :num_trending_topics, :project_slug, :round_to_sec)
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
    @api = AwsApi.new
  end
end
