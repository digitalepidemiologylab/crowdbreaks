class ResultsController < ApplicationController
  def new
    @result = Result.new
    @question = Question.find_by(id: params[:question_id])
    valid_answers = @question.answer_set.get_valid_answers
    @answers = Answer.where(id: valid_answers)
    if params[:tweet_id]
      # Check if tweet_id is valid
      if ActiveTweet.exists?(tweet_id: params[:tweet_id], project_id: @question.project)
        @tweet_id = params[:tweet_id]
      else
        raise ActionController::BadRequest.new('Invalid tweet ID')
      end
    else
      # Check if this is the beginning of the Question sequence
      if @question.id == @question.project.initial_question.to_question.id
        # Find initial tweet
        @tweet_id = ActiveTweet.get_initial_tweet
      else
        raise ActionController::BadRequest.new('Invalid starting question ID')
      end
    end
    @tweet = TweetEmbedding.new(@tweet_id).get_tweet
  end

  def create
    # Find next question 
    next_question = NextQuestion.new(results_params).get_next_question
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
    params.require(:result).permit(:answer_id, :tweet_id).merge({user_id: get_user_id, question_id: params[:question_id], project_id: get_current_project})
  end

  def get_user_id
    if current_user
      return current_user.id 
    else
      # TODO: return guest user ID
      return nil
    end
  end

  def get_current_project
    return Question.find_by(id: params[:question_id]).try(:project_id) || nil
  end
end
