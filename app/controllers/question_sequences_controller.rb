class QuestionSequencesController < ApplicationController
  before_action :set_project, :only => [:show]

  def show
    p @project
    all_questions = @project.questions
    
    @questions = {}
    # collect possible answers for each question
    all_questions.each do |q|
      @questions[q.id] = {'question': q, 'possible_answers': q.answers}
    end

    # transitions
    @transitions = Hash.new{|h, k| h[k] = []}
    @project.transitions.each do |t|
      key = t.from_question_id.nil? ? 'start' : t.from_question_id
      @transitions[key] << {'to_question': t.to_question_id.as_json, 'answer': t.answer_id.as_json}
    end

    # user
    @user_id = current_or_guest_user.id

    # find starting question
    @initial_question_id = @transitions['start'][0][:to_question]
    elastic = Elastic.new(@project.es_index_name)
    @tweet_id = elastic.initial_tweet(@user_id)
  end

  def create
    # Store result
    result = Result.new(results_params)
    project = Project.find_by(id: results_params[:project_id])
    if result.save
      elastic = Elastic.new(project.es_index_name)
      elastic.add_answer(result)

      head :ok, content_type: "text/html"
    else
      head :bad_request
    end
  end

  private

  def results_params
    params.require(:result).permit(:answer_id, :tweet_id, :question_id, :user_id, :project_id)
  end

  def set_project
    return unless params[:id]
    @project = Project.friendly.find(params[:id])
  end
end
