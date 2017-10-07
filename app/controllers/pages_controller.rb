class PagesController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:mturk_tokens]

  def index
  end

  def about
  end

  def test
  end

  def es_test
    client = Crowdbreaks::Client
    @resp = client.cluster.health
    render :test
  end

  def react_test
    project = Project.first
    all_questions = project.questions
    
    @questions = {}
    # collect possible answers for each question
    all_questions.each do |q|
      # @questions[q.id] = {'question': q.as_json, 'possible_answers': q.answer_set.valid_answers.as_json}
      @questions[q.id] = {'question': q, 'possible_answers': q.answer_set.valid_answers}
    end

    # transitions
    @transitions = Hash.new{|h, k| h[k] = []}
    project.transitions.each do |t|
      key = t.from_question_id.nil? ? 'start' : t.from_question_id
      @transitions[key] << {'to_question': t.to_question_id.as_json, 'answer': t.answer_id.as_json}
    end

    # find starting question
    @initial_question_id = @transitions['start'][0][:to_question]

    # find tweetId
    @tweet_id = "20"
  end

  def mturk_tokens
    unless params[:token].present? and params[:key].present?
      render json: {
        status: 400, # bad request
        message: "Key not present. Complete the task and fill in the provided key before submitting."
      }
      return
    end

    # existence test for key pair
    record = MturkToken.find_by(token: params[:token], key: params[:key], used: false)
    if record.present?
      bonus = Mturk.calculate_bonus(record.questions_answered)
      if bonus > 0
        message =  "Key was verfied successfully. You will receive an additional bonus of $#{bonus} upon approval of the assignment."
      else
        message =  "Key was verfied successfully. Thank you for your work."
      end
      record.update_attributes!(used: true, worker_id: params[:worker_id], assignment_id: params[:assignment_id])
      render json: {
        status: 200, # ok
        message: message
      }
    else
      render json: {
        status: 403, # forbidden
        message: "Key is not valid. Please make sure you enter the correct key."
      }
    end
  end
end
