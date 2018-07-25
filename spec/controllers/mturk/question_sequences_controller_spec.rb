require 'rails_helper'

RSpec.describe Mturk::QuestionSequencesController, type: :controller do

  # simplest question sequence
  let!(:project) { FactoryGirl.create(:project) }
  let!(:question) { FactoryGirl.create(:question, project: project) }
  let!(:answer1) { FactoryGirl.create(:answer, questions: [question]) }
  let!(:answer2) { FactoryGirl.create(:answer, questions: [question]) }
  let!(:transition) { FactoryGirl.create(:transition, :starting_question, to_question: question, project: project) }

  let!(:mturk_batch_job) { FactoryGirl.create(:mturk_batch_job, project: project) }
  let!(:task_unsubmitted) { FactoryGirl.create(:task, :unsubmitted, mturk_batch_job: mturk_batch_job) }
  let!(:task_submitted) { FactoryGirl.create(:task, :submitted, mturk_batch_job: mturk_batch_job) }

  describe "GET show" do
    it "throws an error if HIT id is missing in params" do
      get :show
      expect(response).to be_a_bad_request
    end
    it "throws an error if HIT id is invalid" do
      get :show, params: {:hitId => 'invalid-hit-id'}
      expect(response).to be_a_bad_request
    end

    it "unsubmitted task can't be retrieved" do
      get :show, params: {:hitId => task_unsubmitted.hit_id}
      expect(response).to be_a_bad_request
    end

    it "submitted task can be retrieved" do
      get :show, params: {:hitId => task_submitted.hit_id}
      expect(response).to render_template(:show)
    end
  end
end
