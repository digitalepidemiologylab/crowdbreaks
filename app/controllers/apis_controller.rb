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
      "avg_sentiment": @api.get_avg_sentiment(options)
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
    project = Project.find_by(id: api_params_qs[:project_id])
    user_id = api_params_qs[:user_id]
    
    # update count
    project.question_sequences_count = project.results.group(:tweet_id, :user_id).count.length
    project.save

    # update tweet in Redis pool
    @api.update_tweet(project.es_index_name, api_params_qs[:user_id], api_params_qs[:tweet_id])

    # get next question sequence data
    new_tweet_id = @api.get_tweet(project.es_index_name, user_id: user_id)
    options = {locale: I18n.locale.to_s}
    questions_serialized = ActiveModelSerializers::SerializableResource.new(project.questions, options).as_json
    transitions_serialized = ActiveModelSerializers::SerializableResource.new(project.transitions, options).as_json
    questions = {}
    # collect possible answers for each question
    questions_serialized.each do |q|
      questions[q[:id]] = {'id': q[:id], 'question': q[:question], 'answers': q[:answers]}
    end
    transitions = Hash.new{|h, k| h[k] = []}
    transitions_serialized.each do |t|
      transitions[t[:from_question]] << t[:transition]
    end
    num_transitions = Transition.find_path_length(transitions)
    render json: {
      tweet_id: new_tweet_id,
      transitions: transitions,
      num_transitions: num_transitions,
      questions: questions
    }, status: 200
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
      unless resp.empty?
        if FlaskApi.new.tweet_is_valid?(resp[0][0])
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
    end_date = Time.parse(api_params_user_activity.fetch(:end_date, Time.now.to_s))
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

  private

  def api_params_user_activity
    params.require(:user_activity).permit(:start_date, :end_date)
  end
  
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
