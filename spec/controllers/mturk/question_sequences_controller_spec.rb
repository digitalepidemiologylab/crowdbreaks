require 'rails_helper'

RSpec.describe Mturk::QuestionSequencesController, type: :controller do

  # simplest question sequence
  let!(:project) { FactoryBot.create(:project) }
  let!(:question) { FactoryBot.create(:question, project: project) }
  let!(:answer1) { FactoryBot.create(:answer, questions: [question]) }
  let!(:answer2) { FactoryBot.create(:answer, questions: [question]) }
  let!(:transition) { FactoryBot.create(:transition, :starting_question, to_question: question, project: project) }

  # Batch with max assignment 3
  let!(:mturk_batch_job) { FactoryBot.create(:mturk_batch_job, project: project, number_of_assignments: 3) }
  let!(:mturk_tweet1) { FactoryBot.create(:mturk_tweet, mturk_batch_job: mturk_batch_job) }
  let!(:mturk_tweet2) { FactoryBot.create(:mturk_tweet, mturk_batch_job: mturk_batch_job) }

  let!(:mturk_worker1) { FactoryBot.create(:mturk_worker) } # worker 1 hasn't done any work
  let!(:mturk_worker2) { FactoryBot.create(:mturk_worker) } # worker 2 has done tweet 1
  let!(:mturk_worker3) { FactoryBot.create(:mturk_worker) } # worker 3 has done tweet 1 and 2

  let!(:task_unsubmitted) { FactoryBot.create(:task, :unsubmitted, mturk_batch_job: mturk_batch_job) }
  let!(:task_submitted1) { FactoryBot.create(:task, :submitted, mturk_batch_job: mturk_batch_job) }
  let!(:task_submitted2) { FactoryBot.create(:task, :submitted, mturk_batch_job: mturk_batch_job) }
  let!(:task_reviewable1) { FactoryBot.create(:task, :reviewable, mturk_worker: mturk_worker2, mturk_tweet: mturk_tweet1, mturk_batch_job: mturk_batch_job) }
  let!(:task_reviewable2) { FactoryBot.create(:task, :reviewable, mturk_worker: mturk_worker3, mturk_tweet: mturk_tweet1, mturk_batch_job: mturk_batch_job) }
  let!(:task_reviewable3) { FactoryBot.create(:task, :reviewable, mturk_worker: mturk_worker3, mturk_tweet: mturk_tweet2, mturk_batch_job: mturk_batch_job) }

  # Batch with max assignment 2
  let!(:mturk_batch_job2) { FactoryBot.create(:mturk_batch_job, project: project, number_of_assignments: 2) }
  let!(:mturk_tweet3) { FactoryBot.create(:mturk_tweet, mturk_batch_job: mturk_batch_job2) }
  let!(:mturk_worker4) { FactoryBot.create(:mturk_worker) } # worker 4 has done tweet 4
  let!(:mturk_worker5) { FactoryBot.create(:mturk_worker) } # worker 5 hasn't done anything
  let!(:mturk_worker6) { FactoryBot.create(:mturk_worker) } # worker 6 hasn't done anything
  let!(:task_submitted3) { FactoryBot.create(:task, :submitted, mturk_batch_job: mturk_batch_job2) }
  let!(:task_submitted4) { FactoryBot.create(:task, :submitted, mturk_batch_job: mturk_batch_job2) }
  let!(:task_reviewable4) { FactoryBot.create(:task, :reviewable, mturk_worker: mturk_worker4, mturk_tweet: mturk_tweet3, mturk_batch_job: mturk_batch_job2) }
  
  # Batch with unavailable tweet
  let!(:mturk_batch_job3) { FactoryBot.create(:mturk_batch_job, project: project, number_of_assignments: 1) }
  let!(:mturk_tweet4) { FactoryBot.create(:mturk_tweet, mturk_batch_job: mturk_batch_job3) } # valid
  let!(:mturk_tweet5) { FactoryBot.create(:mturk_tweet, :invalid_tweet, mturk_batch_job: mturk_batch_job3) } # invalid
  let!(:task_submitted5) { FactoryBot.create(:task, :submitted, mturk_batch_job: mturk_batch_job3) }
  let!(:task_submitted6) { FactoryBot.create(:task, :submitted, mturk_batch_job: mturk_batch_job3) }

  # SHOW ACTION
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
      get :show, params: {:hitId => task_submitted1.hit_id}
      expect(response).to render_template(:show)
    end

    it "unseen worker should retrieve new task" do
      get :show, params: {
        hitId: task_submitted1.hit_id,
        workerId: 'unseen-worker-id',
        assignmentId: '123'
      }
      expect(assigns(:worker_id)).to eq('unseen-worker-id')
    end

    it "unseen worker should retrieve an existing tweet id belonging to this batch" do
      get :show, params: {
        hitId: task_submitted1.hit_id,
        workerId: 'unseen-worker-id',
        assignmentId: '123'
      }
      expect(assigns(:tweet_id)).not_to eq("")
    end

    it "worker 1 should be receive any of the tweets" do
      get :show, params: {
        hitId: task_submitted1.hit_id,
        workerId: mturk_worker1.worker_id,
        assignmentId: '123'
      }
      expect(assigns(:tweet_id)).to eq(mturk_tweet1.tweet_id.to_s).or eq(mturk_tweet2.tweet_id.to_s)
    end

    it "worker 2 should only receive tweet which he hasn't seen yet" do
      get :show, params: {
        hitId: task_submitted1.hit_id,
        workerId: mturk_worker2.worker_id,
        assignmentId: '123'
      }
      expect(assigns(:tweet_id)).to eq(mturk_tweet2.tweet_id.to_s)
    end

    it "worker 3 should not receive any tweets, since he has done everything" do
      get :show, params: {
        hitId: task_submitted1.hit_id,
        workerId: mturk_worker3.worker_id,
        assignmentId: '123'
      }
      expect(assigns(:tweet_id)).to eq("")
    end
    
    it "worker 1 requests task that which was previous assigned to worker 2" do
      # worker 1 accepts hit
      get :show, params: {
        hitId: task_submitted1.hit_id,
        workerId: mturk_worker1.worker_id,
        assignmentId: '321'
      }
      # expect assignment to be persisted
      task = Task.find(task_submitted1.id)
      expect(task.mturk_worker_id).to eq(mturk_worker1.id)

      # worker 1 returns hits, worker 2 accepts it again
      get :show, params: {
        hitId: task_submitted1.hit_id,
        workerId: mturk_worker2.worker_id,
        assignmentId: '123'
      }
      # expect assignment to be changed
      task.reload
      expect(task.mturk_worker_id).to eq(mturk_worker2.id)
      expect(task.mturk_tweet_id).to eq(mturk_tweet2.id)
    end

    it "does not update task after failed assignment" do
      # worker 3 accepts hit
      get :show, params: {
        hitId: task_submitted1.hit_id,
        workerId: mturk_worker3.worker_id,
        assignmentId: '321'
      }
      # no assignment possible, expect blank state
      task = Task.find(task_submitted1.id)
      expect(task.mturk_tweet_id).to eq(nil)
      expect(task.mturk_worker_id).to eq(nil)
    end

    it "correctly returns on consecutive requests by worker 2" do
      get :show, params: {
        hitId: task_submitted1.hit_id,
        workerId: mturk_worker2.worker_id,
        assignmentId: '321'
      }
      expect(assigns(:tweet_id)).to eq(mturk_tweet2.tweet_id.to_s)
      get :show, params: {
        hitId: task_submitted2.hit_id,
        workerId: mturk_worker2.worker_id,
        assignmentId: '321'
      }
      # no more work available
      expect(assigns(:tweet_id)).to eq("")
    end

    it "correctly sets assignment time after assignment" do
      Timecop.freeze
      task = Task.find(task_submitted1.id)
      expect(task.time_assigned).to eq(nil)
      get :show, params: {
        hitId: task_submitted1.hit_id,
        workerId: mturk_worker2.worker_id,
        assignmentId: '321'
      }
      task.reload
      expect(task.time_assigned).to eq(Time.current)
    end
    
    it "respects number of maximum assignments" do
      task = Task.find(task_submitted3.id)
      expect(task.mturk_tweet_id).to eq(nil)
      get :show, params: {
        hitId: task_submitted3.hit_id,
        workerId: mturk_worker5.worker_id,
        assignmentId: '123'
      }
      # worker 5 is given only tweet
      expect(assigns(:tweet_id)).to eq(mturk_tweet3.tweet_id.to_s)
      get :show, params: {
        hitId: task_submitted4.hit_id,
        workerId: mturk_worker6.worker_id,
        assignmentId: '123'
      }
      # worker 6 wants to do task but max assignment was reached
      expect(assigns(:tweet_id)).to eq("")
    end


    it "only shows available tweets" do
      # worker 1 should receive tweet which is available
      get :show, params: {
        hitId: task_submitted5.hit_id,
        workerId: mturk_worker1.worker_id,
        assignmentId: '123'
      }
      expect(assigns(:tweet_id)).to eq(mturk_tweet4.tweet_id.to_s)

      # worker 1 has done only tweet which is available
      get :show, params: {
        hitId: task_submitted6.hit_id,
        workerId: mturk_worker1.worker_id,
        assignmentId: '123'
      }
      expect(assigns(:tweet_id)).to eq("")
    end

    # FINAL ACTION
    it "creates new records properly on final action" do
      Timecop.freeze(5.minutes.ago)
      # worker 5 is assigned new tweet
      task = Task.find(task_submitted3.id)
      expect(task.mturk_tweet_id).to eq(nil)
      get :show, params: {
        hitId: task_submitted3.hit_id,
        workerId: mturk_worker5.worker_id,
        assignmentId: '123'
      }
      task.reload
      expect(task.mturk_tweet_id).to eq(mturk_tweet3.id)
      expect(task.time_assigned).to eq(Time.current)
      # worker 5 submits his solution
      Timecop.freeze
      post :final, params: {
        task: {
          hit_id: task_submitted3.hit_id,
          worker_id: mturk_worker5.worker_id,
          assignment_id: '123',
          tweet_id: mturk_tweet3.tweet_id,
          results: [
            result: {
              answer_id: answer1.id,
              question_id: question.id,
              tweet_id: mturk_tweet3.tweet_id,
              project_id: project.id
            }
          ]
        }
      }
      expect(response).to be_success
      task.reload
      expect(task.lifecycle_status).to eq('reviewable')
      expect(task.time_completed).to eq(Time.current)
      expect(task.results.count).to eq(1)
      expect(task.results.first.mturk_result).to eq(true)
      expect(task.results.first.question_id).to eq(question.id)
    end

    # CREATE ACTION
    it "creates single results" do
      Timecop.freeze
      # worker 5 is assigned new tweet
      task = Task.find(task_submitted3.id)
      expect(task.mturk_tweet_id).to eq(nil)
      # worker 5 submits single result
      post :create, params: {
        hit_id: task_submitted3.hit_id,
        result: {
          worker_id: mturk_worker5.worker_id,
          assignment_id: '123',
          answer_id: answer1.id,
          question_id: question.id,
          tweet_id: mturk_tweet3.tweet_id,
          project_id: project.id,
          results: []
        }
      }
      expect(response).to be_success
      task.reload
      expect(task.results.count).to eq(1)
      expect(task.results.first.mturk_result).to eq(true)
      expect(task.results.first.question_id).to eq(question.id)
    end
  end
end
