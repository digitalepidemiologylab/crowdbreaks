require 'rails_helper'

RSpec.describe SubmitTasksJob, type: :job do
  # Single tweet/single task batch
  let!(:mturk_batch_job) { FactoryBot.create(:mturk_batch_job, number_of_assignments: 1, sandbox: false) }
  let!(:mturk_worker) { FactoryBot.create(:mturk_worker, :blacklisted) }
  let!(:mturk_tweet) { FactoryBot.create(:mturk_tweet, :available, mturk_batch_job: mturk_batch_job) }
  let!(:task) { FactoryBot.create(:task, :unsubmitted, mturk_batch_job: mturk_batch_job, mturk_tweet: mturk_tweet) }

  describe "#perform_later" do
    it "enqueues a job" do
      ActiveJob::Base.queue_adapter = :test
      expect {
        SubmitTasksJob.perform_later(mturk_batch_job.id)
      }.to have_enqueued_job
    end
  end

  describe "#perform_now" do
    it "sets HIT types and HIT ids and submits task" do
      SubmitTasksJob.perform_now(mturk_batch_job.id)
      mturk_batch_job.reload
      task.reload
      expect(mturk_batch_job.qualification_type_id).to_not eq(nil)
      expect(mturk_batch_job.hittype_id).to_not eq(nil)
      expect(task.hit_id).to_not eq(nil)
      expect(task.submitted?).to be true
    end

    it "blacklists worker by default" do
      SubmitTasksJob.perform_now(mturk_batch_job.id)
      mturk_batch_job.reload
      assert_requested :post, /mturk-requester.us-east-1.amazonaws.com/,
        body: {QualificationTypeId: mturk_batch_job.qualification_type_id, WorkerId: mturk_worker.worker_id, IntegerValue: 1, SendNotification: false}.to_json
    end
  end
end
