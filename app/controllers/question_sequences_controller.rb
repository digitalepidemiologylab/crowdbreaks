class QuestionSequencesController < ApplicationController
  include Response
  authorize_resource class: false

  def show
    @project = Project.friendly.find(params[:project_id])

    # Make sure we are working with the original project
    primary_project = @project.primary_project

    # Only allow access to a private project if it is accessible by user
    redirect_to projects_path unless primary_project.public? || primary_project.accessible_by?(current_user)

    if primary_project.active_question_sequence_id.zero?
      # By default, pick a project as a question sequence (active_question_sequence is initialized as 0)
      question_sequence_project = primary_project
    else
      # Otherwise, find a project with an id
      question_sequence_project = Project.find(primary_project.active_question_sequence_id)
    end

    # Collect question sequence info
    @question_sequence = QuestionSequence.new(question_sequence_project).load
    # Tweet info
    @user_id = current_or_guest_user.id
    tweet = get_value_and_flash_now(
      primary_project.tweet(user_id: @user_id), default: Helpers::Tweet.new(id: 20, text: '', index: nil)
    )
    @tweet_id = tweet.id
    @tweet_index = tweet.index
    # @tweet_id = '1047868518224416769'
    # @tweet_id = '564984221203431000'  # invalid tweet
  end

  def create
    result = Result.new(results_params)

    # If the captcha is verified, save the data
    if params.key?(:recaptcha_response)
      resp = RecaptchaVerification.new.verify(params[:recaptcha_response])
      if !resp['success']
        render json: { errors: resp['error-codes'].to_a, captcha_verified: false }, status: 400
      elsif result.save
        render json: { captcha_verified: true }, status: 200
      else
        render json: { errors: ['internal error'], captcha_verified: true }, status: 400
      end
    elsif result.save
      head :ok
    else
      head :bad_request
    end
  end

  def final
    api = AwsApi.new
    project = Project.find_by(id: final_params[:project_id])
    user_id = final_params[:user_id]
    tweet_id = final_params[:tweet_id]
    tweet_index = final_params[:tweet_index]
    test_mode = final_params[:test_mode]

    render json: {}, status: 400 and return if project.nil?

    if test_mode
      tweet = get_value(project.tweet(user_id: user_id, test_mode: true), default: Helpers::Tweet.new(id: 20, text: '', index: nil))
      render json: tweet.to_h, status: 200 and return
    end

    primary_project = project.primary_project

    # Update count
    if project.results.count.positive?
      project.question_sequences_count = project.results.group(:tweet_id, :user_id).count.length
      project.save
    end

    # Update the tweet on Elasticsearch
    if primary_project.stream_annotation_mode?
      respond_with_flash_now(api.update_tweet(index: tweet_index, user_id: user_id, tweet_id: tweet_id))
    end

    # Get the next tweet
    tweet = get_value(project.tweet(user_id: user_id), default: Helpers::Tweet.new(id: 20, text: '', index: nil))

    # Save logs
    logs = final_params.fetch(:logs, {})
    unless logs.empty?
      qs_log = QuestionSequenceLog.create(log: logs)
      # Associate all previous results with logs
      num_changed = project.results.where(
        { user_id: user_id, tweet_id: tweet_id, question_sequence_log_id: nil, created_at: 1.day.ago..Time.current }
      ).update_all(question_sequence_log_id: qs_log.id)
      if num_changed.zero?
        ErrorLogger.error("Could not find any previous results to Question Sequence Log #{qs_log.id}")
      end
    end
    # Simply return the new tweet ID
    render json: tweet.to_h, status: 200
  end

  private

  def final_params
    params.require(:qs).permit(
      :tweet_id, :tweet_index, :user_id, :project_id, :test_mode,
      logs: [
        :timeInitialized, :delayStart, :delayNextQuestion, :timeMounted, :userTimeInitialized,
        :totalDurationQuestionSequence, :timeQuestionSequenceEnd,
        { results: %i[submitTime timeSinceLastAnswer questionId] },
        { resets: [:resetTime, :resetAtQuestionId, { previousResultLog: %i[submitTime timeSinceLastAnswer questionId] }] }
      ]
    )
  end

  def results_params
    params.require(:result).permit(:answer_id, :tweet_id, :question_id, :user_id, :project_id)
  end
end
