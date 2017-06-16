class QuestionSequencesController < ApplicationController
  def show
    @result = Result.new
    # @question = Question.find_by(id: params[:question_id])
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
        response = elastic.initial_tweet
        if !response['hits']['hits'].empty?
          @tweet_id = response['hits']['hits'].first['_id']
        else
          raise "This index contains no tweets"
        end
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
    # Find next question
    next_question = NextQuestion.new(results_params).next_question
    @result = Result.new(results_params)
    if @result.save
      # also store in meta field of tweet in ES 
      elastic = Elastic.new(@project.es_index_name)
      elastic.add_answer(@result.tweet_id, @result.question_id, @result.answer_id)

      if next_question.nil?
        # End of question sequence
        redirect_to projects_path
        flash[:notice] = "Question sequence successfully completed!"
      else
        # Go to next question
        respond_to do |format|
          # format.html { redirect_to new_question_result_path(next_question, tweet_id: results_params[:tweet_id]) }
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

  private

  def results_params
    params.require(:result).permit(:answer_id, :tweet_id, :question_id).merge(user_id: user_id, project_id: @project.id)
  end

  def user_id
    if current_user
      current_user.id
    else
      # TODO: return guest user IDI
      nil
    end
  end
end
