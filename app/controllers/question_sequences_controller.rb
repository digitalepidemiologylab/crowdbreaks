class QuestionSequencesController < ApplicationController
  before_action :set_project

  def show
    @result = Result.new
    @question = @project.initial_question
    raise 'Question not found' if @question.nil?
    valid_answers = @question.answer_set.valid_answers
    @answers = Answer.where(id: valid_answers)
    elastic = Elastic.new(@project.es_index_name)

    # initialize question counter
    @question_counter ||= 0

    # fetch tweet
    if !@tweet_id.present?
      # case beginning of question sequence
      @tweet_id = elastic.initial_tweet(user_id)
    end
    @tweet = TweetEmbedding.new(@tweet_id).tweet_embedding
    
    # fetch mturk token if provided
    @mturk_token ||= params[:mturk_token]
    if @mturk_token.present?
      valid, message = MturkToken.validate_token(@mturk_token)
      if !valid
        redirect_to project_path
        flash[:alert] = message
      end
    end
  end

  def create
    @result = Result.new(results_params)
    if @result.save
      # also store in meta field of tweet in ES if meta field is provided
      elastic = Elastic.new(@project.es_index_name)
      elastic.add_answer(@result)

      # Find next question
      next_question = NextQuestion.new(results_params).next_question

      # fetch mturk token if provided
      @mturk_token ||= params[:mturk_token]
      @question_counter = params[:question_counter].to_i + 1
      MturkToken.update_answer_count(token: @mturk_token, count: @question_counter) if @mturk_token.present?

      if next_question.nil?
        # End of question sequence
        if @mturk_token.present?
          @mturk_key = MturkToken.return_key(@mturk_token)        
        end

        # update answer count only at the end of the question sequence
        elastic.update_answer_count(@result.tweet_id)
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
