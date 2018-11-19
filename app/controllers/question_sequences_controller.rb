class QuestionSequencesController < ApplicationController
  authorize_resource class: false

  def show
    @project = Project.friendly.find(params[:project_id])
    # Collect question sequence info
    @question_sequence = QuestionSequence.new(@project).load
    # Other
    @user_id = current_or_guest_user.id
    # Fetch new tweet ID
    @tweet_id = FlaskApi.new.get_tweet(@project.es_index_name, user_id: @user_id)

    # @tweet_id = '1047868518224416769'
    # @tweet_id = '564984221203431000'  # invalid tweet
    # @tweet_id = '955454023519391744'  # invalid tweet
  end

  def create
    result = Result.new(results_params)

    # if captcha is verified save data
    if params.has_key?(:recaptcha_response)
      resp = RecaptchaVerification.new.verify(params[:recaptcha_response])
      if not resp['success']
        render json: { errors: resp['error-codes'].to_a, captcha_verified: false }, status: 400
      else
        if result.save
          render json: { captcha_verified: true }, status: 200
        else
          render json: { errors: ['internal error'], captcha_verified: true }, status: 400
        end
      end
    else
      if result.save
        head :ok
      else
        head :bad_request
      end
    end
  end


  def final
    api = FlaskApi.new
    project = Project.find_by(id: final_params[:project_id])
    user_id = final_params[:user_id]
    tweet_id = final_params[:tweet_id]
    test_mode = final_params[:test_mode]

    if project.nil?
      render json: {}, status: 400 and return
    end

    if test_mode 
      new_tweet_id = api.get_tweet(project.es_index_name, user_id: user_id)
      render json: {tweet_id: new_tweet_id}, status: 200 and return
    end
    
    # update count
    if project.results.count > 0
      project.question_sequences_count = project.results.group(:tweet_id, :user_id).count.length
      project.save
    end

    # update tweet in Redis pool
    api.update_tweet(project.es_index_name, user_id, tweet_id)

    # get next tweet
    new_tweet_id = api.get_tweet(project.es_index_name, user_id: user_id)

    # save logs
    logs = final_params.fetch(:logs, {}) 
    unless logs.empty?
      qs_log = QuestionSequenceLog.create(log: logs)
      # associated all previous results with logs
      num_changed = project.results.where({user_id: user_id, tweet_id: tweet_id, question_sequence_log_id: nil, created_at: 1.day.ago..Time.current}).update_all(question_sequence_log_id: qs_log.id)
      if num_changed == 0
        Rails.logger.error("Could not find any previous results to Question Sequence Log #{qs_log.id}")
      end
    end
    # simply return new tweet ID
    render json: {
      tweet_id: new_tweet_id,
    }, status: 200
  end

  private

  def final_params
    params.require(:qs).permit(:tweet_id, :user_id, :project_id, :test_mode,
                               logs: [:timeInitialized, :answerDelay, :timeMounted, :userTimeInitialized, :totalDurationQuestionSequence, :timeQuestionSequenceEnd,
                                      results: [:submitTime, :timeSinceLastAnswer, :questionId],
                                      resets: [:resetTime, :resetAtQuestionId, previousResultLog: [:submitTime, :timeSinceLastAnswer, :questionId]]])
  end

  def results_params
    params.require(:result).permit(:answer_id, :tweet_id, :question_id, :user_id, :project_id)
  end
end
