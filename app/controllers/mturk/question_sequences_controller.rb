class Mturk::QuestionSequencesController < ApplicationController
  after_action :allow_cross_origin, only: [:show]
  layout 'mturk'

  def show
    authorize! :show, :mturk_question_sequence

    # Mturk info
    @assignment_id = params['assignmentId']
    @hit_id = params['hitId']
    
    @project = Project.first

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
    @tweet_id = Elastic.new(@project.es_index_name).initial_tweet(@user_id)
    
    # other
    @user_id = current_or_guest_user.id
    @translations = I18n.backend.send(:translations)[I18n.locale][:question_sequences]

  end


  private

  def allow_cross_origin
    response.headers.delete "X-Frame-Options"
  end
end
