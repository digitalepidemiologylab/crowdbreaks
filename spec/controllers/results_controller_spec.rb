require 'rails_helper'

RSpec.describe ResultsController, type: :controller do
  # general setup
  let!(:answer_1) { create(:answer, answer: "Answer 1") }
  let!(:answer_2) { create(:answer, answer: "Answer 2") }
  let!(:answer_3) { create(:answer, answer: "Answer 3") }
  let!(:answer_set) { create(:answer_set, name: 'default', answer0: answer_1, answer1: answer_2, answer2: answer_3) }
  
  let!(:project_1) { create(:project, title: "Scenario 1") }
  let!(:question_1) { create(:question, question: 'Question 1.1', project: project_1, answer_set: answer_set) }
  let!(:question_2) { create(:question, question: 'Question 1.2', project: project_1, answer_set: answer_set) } 
  let!(:transition_1) { create(:transition, project: project_1, from_question: nil, to_question: question_1) } 
  let!(:transition_2) { create(:transition, project: project_1, from_question: question_1, to_question: question_2) } 
  let!(:active_tweet_1) { create(:active_tweet, project: project_1) }

  let!(:project_2) { create(:project, title: "Scenario 2") }
  let!(:transition_3) { create(:transition, project: project_2, from_question: question_1, to_question: question_2) } 

  def valid_params
    { question_id: question_1.id }
  end
  
  def invalid_params
    { question_id: question_2.id }
  end

  describe "GET #new" do
    context "with valid initial question" do
      before { get :new, params: valid_params }
      it { expect(response).to render_template :new  }
    end

    context "with initial question not first question in sequence" do
      it "should raise error" do
        expect{ get :new, params: invalid_params }.to raise_error('Invalid starting question ID')
      end
    end

    context "with invalid initial question" do
      it "should raise error" do
        expect{ get :new, params: project_2.initial_question }.to raise_error("Project #{project_2.title} does not have a valid first Question")
      end
    end
  end
end
