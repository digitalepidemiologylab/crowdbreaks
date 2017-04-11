class ResultsController < ApplicationController
  def new
    @result = Result.new
    @question = Question.find_by(id: params[:question_id])
    valid_answers = @question.answer_set.valid_answers
    @answers = Answer.where(id: valid_answers)

    # case beginning of question sequence
    if !params[:tweet_id]
      # Check if this is a valid beginning of the question sequence
      if @question.id == @question.project.initial_question.to_question.id
        # Find initial tweet
        @tweet_id = ActiveTweet.initial_tweet
      else
        raise ActionController::BadRequest, 'Invalid starting question ID'
      end
    else
      # Check if given tweet_id is valid
      if ActiveTweet.exists?(tweet_id: params[:tweet_id], project_id: @question.project)
        @tweet_id = params[:tweet_id]
      else
        raise ActionController::BadRequest, 'Invalid tweet ID'
      end
    end
    @tweet = TweetEmbedding.new(@tweet_id).tweet_embedding
  end

  def create
    # Find next question
    next_question = NextQuestion.new(results_params).next_question
    @result = Result.new(results_params)
    if @result.save
      if next_question.nil?
        # End of question sequence
        redirect_to projects_path
        flash[:notice] = "Question sequence successfully completed!"
      else
        # Go to next question
        respond_to do |format|
          format.html { redirect_to new_question_result_path(next_question, tweet_id: results_params[:tweet_id]) }
        end
      end
    else
      redirect_to projects_path
      flash[:alert] = "An error has occurred"
    end
  end

  private

  def results_params
    # params.require(:result).permit(:answer_id, :tweet_id).merge({ user_id: user_id, question_id: params[:question_id], project_id: current_project })
    params.require(:result).permit(:answer_id, :tweet_id).merge(user_id: user_id, question_id: params[:question_id], project_id: current_project)
  end

  def user_id
    if current_user
      current_user.id
    else
      # TODO: return guest user IDI
      nil
    end
  end

  def current_project
    Question.find_by(id: params[:question_id]).try(:project_id) || nil
  end
end
