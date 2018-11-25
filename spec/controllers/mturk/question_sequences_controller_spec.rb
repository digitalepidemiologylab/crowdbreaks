require 'rails_helper'

RSpec.describe Mturk::QuestionSequencesController, type: :controller do

  # shared 
  let!(:qs_log_mturk) { FactoryBot.create(:question_sequence_log, :mturk) }
  let!(:qs_log_public) { FactoryBot.create(:question_sequence_log, :public) }

  # simplest question sequence
  let!(:project) { FactoryBot.create(:project) }
  let!(:question) { FactoryBot.create(:question, project: project) }
  let!(:answer1) { FactoryBot.create(:answer, questions: [question]) }
  let!(:answer2) { FactoryBot.create(:answer, questions: [question]) }
  let!(:transition) { FactoryBot.create(:transition, :starting_question, to_question: question, project: project) }

  # Batch with max assignment 3
  let!(:mturk_batch_job) { FactoryBot.create(:mturk_batch_job, :submitted, project: project, number_of_assignments: 3) }
  let!(:mturk_tweet1) { FactoryBot.create(:mturk_tweet, mturk_batch_job: mturk_batch_job) }
  let!(:mturk_tweet2) { FactoryBot.create(:mturk_tweet, mturk_batch_job: mturk_batch_job) }

  let!(:mturk_worker1) { FactoryBot.create(:mturk_worker) } # worker 1 hasn't done any work
  let!(:mturk_worker2) { FactoryBot.create(:mturk_worker) } # worker 2 has done tweet 1
  let!(:mturk_worker3) { FactoryBot.create(:mturk_worker) } # worker 3 has done tweet 1 and 2

  let!(:task_unsubmitted) { FactoryBot.create(:task, :unsubmitted, mturk_batch_job: mturk_batch_job) }
  let!(:task_submitted1) { FactoryBot.create(:task, :submitted, mturk_batch_job: mturk_batch_job) }
  let!(:task_submitted2) { FactoryBot.create(:task, :submitted, mturk_batch_job: mturk_batch_job) }
  let!(:task_reviewable1) { FactoryBot.create(:task, :completed, mturk_worker: mturk_worker2, mturk_tweet: mturk_tweet1, mturk_batch_job: mturk_batch_job) }
  let!(:task_reviewable2) { FactoryBot.create(:task, :completed, mturk_worker: mturk_worker3, mturk_tweet: mturk_tweet1, mturk_batch_job: mturk_batch_job) }
  let!(:task_reviewable3) { FactoryBot.create(:task, :completed, mturk_worker: mturk_worker3, mturk_tweet: mturk_tweet2, mturk_batch_job: mturk_batch_job) }

  # Batch with max assignment 2
  let!(:mturk_batch_job2) { FactoryBot.create(:mturk_batch_job, :submitted, project: project, number_of_assignments: 2) }
  let!(:mturk_tweet3) { FactoryBot.create(:mturk_tweet, mturk_batch_job: mturk_batch_job2) }
  let!(:mturk_worker4) { FactoryBot.create(:mturk_worker) } # worker 4 has done tweet 4
  let!(:mturk_worker5) { FactoryBot.create(:mturk_worker) } # worker 5 hasn't done anything
  let!(:mturk_worker6) { FactoryBot.create(:mturk_worker) } # worker 6 hasn't done anything
  let!(:task_submitted3) { FactoryBot.create(:task, :submitted, mturk_batch_job: mturk_batch_job2) }
  let!(:task_submitted4) { FactoryBot.create(:task, :submitted, mturk_batch_job: mturk_batch_job2) }
  let!(:task_reviewable4) { FactoryBot.create(:task, :completed, mturk_worker: mturk_worker4, mturk_tweet: mturk_tweet3, mturk_batch_job: mturk_batch_job2) }

  # Batch with unavailable tweet
  let!(:mturk_batch_job3) { FactoryBot.create(:mturk_batch_job, :submitted, project: project, number_of_assignments: 1) }
  let!(:mturk_tweet4) { FactoryBot.create(:mturk_tweet, :available, mturk_batch_job: mturk_batch_job3) }
  let!(:mturk_tweet5) { FactoryBot.create(:mturk_tweet, :unavailable, mturk_batch_job: mturk_batch_job3) }
  let!(:task_submitted5) { FactoryBot.create(:task, :submitted, mturk_batch_job: mturk_batch_job3) }
  let!(:task_submitted6) { FactoryBot.create(:task, :submitted, mturk_batch_job: mturk_batch_job3) }

  # Batch with max_tasks_per_worker
  let!(:mturk_batch_job4) { FactoryBot.create(:mturk_batch_job, :submitted, project: project, number_of_assignments: 1, max_tasks_per_worker: 1) }
  let!(:mturk_tweet6) { FactoryBot.create(:mturk_tweet, mturk_batch_job: mturk_batch_job4) }
  let!(:mturk_tweet7) { FactoryBot.create(:mturk_tweet, mturk_batch_job: mturk_batch_job4) }
  let!(:task_submitted7) { FactoryBot.create(:task, :submitted, mturk_batch_job: mturk_batch_job4) }
  let!(:task_submitted8) { FactoryBot.create(:task, :submitted, mturk_batch_job: mturk_batch_job4) }
  let!(:mturk_worker8) { FactoryBot.create(:mturk_worker) }

  # Batch with before and after availability checking
  let!(:mturk_batch_job5) { FactoryBot.create(:mturk_batch_job, :submitted, project: project, number_of_assignments: 1, check_availability: :before_and_after) }
  let!(:mturk_tweet8) { FactoryBot.create(:mturk_tweet, :available, mturk_batch_job: mturk_batch_job5) }
  let!(:mturk_tweet9) { FactoryBot.create(:mturk_tweet, :wrongly_set_to_available, mturk_batch_job: mturk_batch_job5) }
  let!(:task_submitted9) { FactoryBot.create(:task, :submitted, mturk_batch_job: mturk_batch_job5) }
  let!(:task_submitted10) { FactoryBot.create(:task, :submitted, mturk_batch_job: mturk_batch_job5) }

  # Batch with large tweet ids
  let!(:mturk_batch_job6) { FactoryBot.create(:mturk_batch_job, :submitted, project: project, number_of_assignments: 1, check_availability: :before) }
  let!(:mturk_tweet10) { FactoryBot.create(:mturk_tweet, :available, tweet_id: '1050562002664468480', mturk_batch_job: mturk_batch_job6) }
  let!(:task_submitted11) { FactoryBot.create(:task, :submitted, mturk_batch_job: mturk_batch_job6) }

  # Reassign tweet after worker didn't do it
  let!(:mturk_batch_job7) { FactoryBot.create(:mturk_batch_job, :submitted, project: project, number_of_assignments: 1) }
  let!(:mturk_tweet11) { FactoryBot.create(:mturk_tweet, :available, mturk_batch_job: mturk_batch_job7) }
  let!(:task_submitted12) { FactoryBot.create(:task, :submitted, mturk_batch_job: mturk_batch_job7) }

  # Store result regardless of whether task could be found
  let!(:mturk_batch_job8) { FactoryBot.create(:mturk_batch_job, :submitted, project: project, number_of_assignments: 1) }
  let!(:mturk_tweet12) { FactoryBot.create(:mturk_tweet, :available, mturk_batch_job: mturk_batch_job8) }
  let!(:task_submitted13) { FactoryBot.create(:task, :submitted, mturk_batch_job: mturk_batch_job8) }

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

    it "respects max_tasks_per_worker" do
      get :show, params: {
        hitId: task_submitted7.hit_id,
        workerId: mturk_worker8.worker_id,
        assignmentId: '123'
      }
      # receive tweet but exclude from future tasks
      expect(assigns(:tweet_id)).to eq(mturk_tweet6.tweet_id.to_s).or eq(mturk_tweet7.tweet_id.to_s)
      assert_requested :post, /mturk-requester(?:-sandbox)?.us-east-1.amazonaws.com/,
        body: {QualificationTypeId: mturk_batch_job4.qualification_type_id, WorkerId: mturk_worker8.worker_id}.to_json
    end

    it "detects wrongly assigned availability with before_and_after check availability option" do
      # make sure wrongly assigned tweet is not being retrieved
      get :show, params: {
        hitId: task_submitted9.hit_id,
        workerId: mturk_worker8.worker_id,
        assignmentId: '123'
      }
      expect(assigns(:tweet_id)).to eq(mturk_tweet8.tweet_id.to_s)
      get :show, params: {
        hitId: task_submitted10.hit_id,
        workerId: mturk_worker8.worker_id,
        assignmentId: '123'
      }
      expect(assigns(:tweet_id)).to eq("")
    end

    # FINAL ACTION
    it "re-assign tweet after worker didn't do it" do
      # worker 8 is assigned new tweet
      Timecop.freeze(5.minutes.ago)
      task = Task.find(task_submitted13.id)
      tweet = MturkTweet.find(mturk_tweet12.id)
      get :show, params: {
        hitId: task.hit_id,
        workerId: mturk_worker8.worker_id,
        assignmentId: '123'
      }
      expect(assigns(:tweet_id)).to eq(tweet.tweet_id.to_s)
      task.reload
      expect(task.mturk_worker_id).to eq(mturk_worker8.id)
      # worker 8 didn't finish work and returns it. Task is then not properly re-assigned and worker 6 submit his result. 
      # In this case we want to store the results anyway in order not to lose anything
      expect(Result.count).to eq(0)
      expect(Rails.logger).to receive(:error).with(/was assigned to worker/)
      post :final, params: {
        task: {
          hit_id: task.hit_id,
          worker_id: mturk_worker6.worker_id,
          assignment_id: '123',
          tweet_id: tweet.tweet_id,
          logs: qs_log_mturk.log,
          results: [
            result: {
              answer_id: answer1.id,
              question_id: question.id,
              tweet_id: tweet.tweet_id,
              project_id: project.id
            }
          ]
        }
      }
      expect(response).to be_successful
      task.reload
      expect(Result.count).to eq(1)
      # task has been successfully re-assigned
      expect(task.mturk_worker_id).to eq(mturk_worker6.id)
    end

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
          logs: qs_log_mturk.log,
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
      expect(response).to be_successful
      task.reload
      expect(task.lifecycle_status).to eq('completed')
      expect(task.time_completed).to eq(Time.current)
      expect(task.results.count).to eq(1)
      expect(task.results.first.res_type).to eq('mturk')
      expect(task.results.first.question_id).to eq(question.id)
      expect(task.mturk_tweet.tweet_id).to eq(task.results.last.tweet_id)
    end

    it "creates new records properly on final action" do
      # worker 8 is assigned new tweet
      task = Task.find(task_submitted11.id)
      expect(task.mturk_tweet_id).to eq(nil)
      get :show, params: {
        hitId: task_submitted11.hit_id,
        workerId: mturk_worker8.worker_id,
        assignmentId: '123'
      }
      task.reload
      expect(task.mturk_tweet_id).to eq(mturk_tweet10.id)
      expect(task.mturk_tweet.tweet_id).to eq(mturk_tweet10.tweet_id)
      expect(task.results.count).to eq(0)
      # worker 8 submits his solution
      post :final, params: {
        task: {
          hit_id: task.hit_id,
          worker_id: mturk_worker8.worker_id,
          assignment_id: '123',
          tweet_id: task.mturk_tweet.tweet_id,
          logs: qs_log_mturk.log,
          results: [
            result: {
              answer_id: answer1.id,
              question_id: question.id,
              tweet_id: task.mturk_tweet.tweet_id,
              project_id: project.id
            }
          ]
        }
      }
      expect(response).to be_successful
      task.reload
      expect(task.mturk_tweet.tweet_id).to eq(task.results.last.tweet_id)
    end

    it "stores mturk results regardless of whether task could be found" do
      # worker 8 is assigned new tweet
      task = Task.find(task_submitted12.id)
      expect(task.mturk_tweet_id).to eq(nil)
      get :show, params: {
        hitId: task.hit_id,
        workerId: mturk_worker8.worker_id,
        assignmentId: '123'
      }
      task.reload
      expect(task.mturk_tweet_id).to eq(mturk_tweet11.id)
      expect(task.mturk_tweet.tweet_id).to eq(mturk_tweet11.tweet_id)
      expect(Result.count).to eq(0)
      # worker 8 submits his solution with wrong HIT id
      expect(Rails.logger).to receive(:error).with('Task for invalid-hit-id could not be found')
      post :final, params: {
        task: {
          hit_id: 'invalid-hit-id',
          worker_id: mturk_worker8.worker_id,
          assignment_id: '123',
          tweet_id: task.mturk_tweet.tweet_id,
          logs: qs_log_mturk.log,
          results: [
            result: {
              answer_id: answer1.id,
              question_id: question.id,
              tweet_id: task.mturk_tweet.tweet_id,
              project_id: project.id
            }
          ]
        }
      }
      expect(Result.count).to eq(1)
      expect(Result.last.task).to eq(nil)
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
      expect(response).to be_successful
      task.reload
      expect(task.results.count).to eq(1)
      expect(task.results.first.res_type).to eq('mturk')
      expect(task.results.first.question_id).to eq(question.id)
    end
  end
end
