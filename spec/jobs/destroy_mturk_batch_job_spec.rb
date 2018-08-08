require 'rails_helper'

RSpec.describe DestroyMturkBatchJob, type: :job do
  let!(:mturk_batch_job) { FactoryBot.create(:mturk_batch_job) }
  let!(:mturk_tweet) { FactoryBot.create(:mturk_tweet, mturk_batch_job: mturk_batch_job) }
  let!(:mturk_worker) { FactoryBot.create(:mturk_worker) }
  let!(:task1) { FactoryBot.create(:task, :unsubmitted, mturk_batch_job: mturk_batch_job) }
  let!(:task2) { FactoryBot.create(:task, :submitted, mturk_batch_job: mturk_batch_job) }
  let!(:task3) { FactoryBot.create(:task, :reviewable, mturk_worker: mturk_worker, mturk_tweet: mturk_tweet, mturk_batch_job: mturk_batch_job) }
  let!(:result) { FactoryBot.create(:result, :through_mturk, task: task3) }

  describe "#perform_later" do
    it "enqueues a job" do
      ActiveJob::Base.queue_adapter = :test
      expect {
        DestroyMturkBatchJob.perform_later(mturk_batch_job.id)
      }.to have_enqueued_job
    end
  end

  describe "#perform_now" do
    it "destroys empty batch job" do
      DestroyMturkBatchJob.perform_now(mturk_batch_job.id)
      expect(MturkBatchJob.where(id: mturk_batch_job.id)).not_to exist
    end

    it "destroys batch including associated records" do
      DestroyMturkBatchJob.perform_now(mturk_batch_job.id, destroy_results: true)
      expect(MturkBatchJob.where(id: mturk_batch_job.id)).not_to exist
      expect(Task.where(id: task1.id)).not_to exist
      expect(Task.where(id: task2.id)).not_to exist
      expect(Task.where(id: task3.id)).not_to exist
      expect(MturkTweet.where(id: mturk_tweet.id)).not_to exist
      expect(Result.where(id: result.id)).not_to exist

      # paranoid testing just to make sure
      expect(Task.count).to eq(0)
      expect(Result.count).to eq(0)
      expect(MturkBatchJob.count).to eq(0)
      expect(MturkTweet.count).to eq(0)

      # workers should not be deleted
      expect(MturkWorker.where(id: mturk_worker.id)).to exist
    end

    it "destroys batch without associated records" do
      expect(Result.count).to eq(1)
      DestroyMturkBatchJob.perform_now(mturk_batch_job.id, destroy_results: false)
      expect(MturkBatchJob.where(id: mturk_batch_job.id)).not_to exist
      expect(Task.where(id: task1.id)).not_to exist
      expect(Task.where(id: task2.id)).not_to exist
      expect(Task.where(id: task3.id)).not_to exist
      expect(MturkTweet.where(id: mturk_tweet.id)).not_to exist
      
      # paranoid testing just to make sure
      expect(Task.count).to eq(0)
      expect(MturkBatchJob.count).to eq(0)
      expect(MturkTweet.count).to eq(0)

      # workers and results should still be present
      expect(MturkWorker.where(id: mturk_worker.id)).to exist
      expect(Result.where(id: result.id)).to exist
      expect(Result.count).to eq(1)
    end
  end
end
