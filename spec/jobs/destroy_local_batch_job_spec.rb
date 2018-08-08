require 'rails_helper'

RSpec.describe DestroyLocalBatchJob, type: :job do
  let!(:local_batch_job) { FactoryBot.create(:local_batch_job) }
  let!(:local_tweet1) { FactoryBot.create(:local_tweet, local_batch_job: local_batch_job) }
  let!(:local_tweet2) { FactoryBot.create(:local_tweet, local_batch_job: local_batch_job) }

  describe "#perform_later" do
    it "enqueues a job" do
      ActiveJob::Base.queue_adapter = :test
      expect {
        DestroyLocalBatchJob.perform_later(local_batch_job.id)
      }.to have_enqueued_job
    end
  end

  describe "#perform_now" do
    it "destroys local batch job" do
      expect(LocalTweet.count).to eq(2)
      expect(LocalBatchJob.count).to eq(1)
      DestroyLocalBatchJob.perform_now(local_batch_job.id)
      expect(LocalBatchJob.where(id: local_batch_job.id)).not_to exist
      expect(LocalTweet.where(id: local_tweet1.id)).not_to exist
      expect(LocalTweet.where(id: local_tweet2.id)).not_to exist

      expect(LocalTweet.count).to eq(0)
      expect(LocalBatchJob.count).to eq(0)
    end
  end
end
