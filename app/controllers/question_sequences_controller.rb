class QuestionSequencesController < ApplicationController

  def show
    authorize! :show, :question_sequence
    @project = Project.friendly.find(params[:project_id])

    # collect JSON data
    options = {locale: I18n.locale.to_s}
    questions_serialized = ActiveModelSerializers::SerializableResource.new(@project.questions, options).as_json
    transitions_serialized = ActiveModelSerializers::SerializableResource.new(@project.transitions, options).as_json

    # questions
    @questions = {}
    # collect possible answers for each question
    questions_serialized.each do |q|
      @questions[q[:id]] = {'id': q[:id], 'question': q[:question], 'answers': q[:answers]}
    end

    # transitions
    @transitions = Hash.new{|h, k| h[k] = []}
    transitions_serialized.each do |t|
      @transitions[t[:from_question]] << t[:transition]
    end
    @num_transitions = find_path_length(@transitions)
    
    # other
    @user_id = current_or_guest_user.id
    @translations = I18n.backend.send(:translations)[I18n.locale][:question_sequences]

    # find starting question
    @initial_question_id = @project.initial_question.id
    # @tweet_id = Elastic.new(@project.es_index_name).initial_tweet(@user_id)
    @tweet_id = FlaskApi.new.get_tweet(@project.es_index_name, user_id: @user_id)
    @tweet_id = '20'

    # @tweet_id = '564984221203431000'  # invalid tweet
    # @tweet_id = '955454023519391744'  # invalid tweet
  end

  def create
    authorize! :create, Result
    # Store result
    result = Result.new(results_params)
    project = Project.find_by(id: results_params[:project_id])
    if result.save
      head :ok, content_type: "text/html"
    else
      head :bad_request
    end
  end

  private

  def results_params
    params.require(:result).permit(:answer_id, :tweet_id, :question_id, :user_id, :project_id)
  end

  def find_path_length(transitions)
    # Note: This gives the length of an arbitrary path from the start question 
    if not transitions.include?('start')
      return 0
    end
    len = 0
    current = transitions['start']
    while current.length > 0 do
      len += 1
      next_question = current[0][:to_question]
      current = transitions[next_question]
    end
    return len
  end
end
