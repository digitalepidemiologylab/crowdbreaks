class QuestionSequencesController < ApplicationController
  before_action :set_project

  def show
    @result = Result.new
    @question = @project.initial_question
    raise 'Question not found' if @question.nil?
    valid_answers = @question.answer_set.valid_answers
    @answers = Answer.where(id: valid_answers)
    elastic = Elastic.new(@project.es_index_name)

    # case beginning of question sequence
    if !params[:tweet_id]
      # Check if this is a valid beginning of the question sequence
      if @question.id == @project.initial_question.id
        # Find initial tweet id
        @tweet_id = elastic.initial_tweet(user_id)
      else
        raise ActionController::BadRequest, 'Invalid starting question ID'
      end
    else
      @tweet_id = params[:tweet_id]
      if !elastic.validate_tweet_id(@tweet_id)
        raise ActionController::BadRequest, 'Invalid tweet ID'
      end
    end
    @tweet = TweetEmbedding.new(@tweet_id).tweet_embedding
  end

  def create
    @result = Result.new(results_params)
    if @result.save
      # also store in meta field of tweet in ES if meta field is provided
      elastic = Elastic.new(@project.es_index_name)
      elastic.add_answer(@result)

      # Find next question
      next_question = NextQuestion.new(results_params).next_question
      if next_question.nil?
        # End of question sequence
        render :final
      else
        # Go to next question
        respond_to do |format|
          @question = next_question
          @tweet_id = results_params[:tweet_id]
          @tweet = TweetEmbedding.new(@tweet_id).tweet_embedding
          valid_answers = @question.answer_set.valid_answers
          @answers = Answer.where(id: valid_answers)
          @result = Result.new
          format.html { render :show }
        end
      end
    else
      redirect_to projects_path
      flash[:alert] = "An error has occurred"
    end
  end

  def final
  end


  private

  def results_params
    params.require(:result).permit(:answer_id, :tweet_id, :question_id).merge(user_id: user_id, project_id: @project.id)
  end

  def user_id
    current_or_guest_user.id
  end
end
