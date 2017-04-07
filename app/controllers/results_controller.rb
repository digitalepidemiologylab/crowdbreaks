class ResultsController < ApplicationController
  def new
    @result = Result.new
    @question = Question.find_by(id: params[:question_id])
    valid_answers = @question.answer_set.get_valid_answers
    @answers = Answer.where(id: valid_answers)
    if params[:tweet_id]
      tweet_id = params[:tweet_id]
    else
      tweet_id = get_tweet_id()
    end
    @tweet = TweetEmbedding.new(tweet_id).get_tweet
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
          format.html { redirect_to new_question_result_path(next_question) }
        end
      end
    else
      redirect_to projects_path
      flash[:alert] = "An error has occurred"
    end
  end


  private

  def get_tweet_id
    # 847769197962723328
    847878099614171136
  end

  def results_params
    # params.require(:result).permit(:answer_id).merge({user_id: get_user_id, question_id: params[:question_id], tweet_id: params[:tweet_id] , project_id: get_current_project})
    params.require(:result).permit(:answer_id).merge({user_id: get_user_id, question_id: params[:question_id], project_id: get_current_project})
  end

  def get_user_id
    if current_user
      return current_user.id 
    else
      return nil
    end
  end

  def get_current_project
    return Question.find_by(id: params[:question_id]).project_id
  end
end
