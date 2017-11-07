class Mturk::QuestionSequencesController < ApplicationController
  after_action :allow_cross_origin, only: [:show]
  layout 'mturk'

  def show
    authorize! :show, :mturk_question_sequence

    # Mturk info
    @assignment_id = params['assignmentId']
    @preview_mode = ((@assignment_id == "ASSIGNMENT_ID_NOT_AVAILABLE") or (not @assignment_id.present?))

    # retrieve task for hit id
    task = Task.find_by(hit_id: params['hitId'])
    @project = task.mturk_batch_job.project

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
    
    # find starting question
    @initial_question_id = @project.initial_question.id
    @tweet_id = task.tweet_id
    
    # other
    @user_id = current_or_guest_user.id
    @translations = I18n.backend.send(:translations)[:en][:question_sequences]
  end


  def create
    authorize! :create, Result
    # Store result
    result = Result.new(results_params)
    p params
    p params[:assignment_id]
    # project = Project.find_by(id: results_params[:project_id])
    if result.save
      # elastic = Elastic.new(project.es_index_name)
      # elastic.add_answer(result)
      head :ok, content_type: "text/html"
    else
      head :bad_request
    end
  end


  private

  def results_params
    params.require(:result).permit(:answer_id, :tweet_id, :question_id, :user_id, :project_id)
  end

  def allow_cross_origin
    response.headers.delete "X-Frame-Options"
  end
end
