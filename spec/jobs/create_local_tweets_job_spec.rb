require 'rails_helper'

RSpec.describe CreateLocalTweetsJob, type: :job do
  let!(:local_batch_job) { FactoryBot.create(:local_batch_job) }

  let!(:local_batch_job2) { FactoryBot.create(:local_batch_job) }
  let!(:local_tweet1) { FactoryBot.create(:local_tweet, local_batch_job: local_batch_job2) }
  let!(:local_tweet2) { FactoryBot.create(:local_tweet, local_batch_job: local_batch_job2) }

  describe "#perform_later" do
    it "enqueues a job" do
      ActiveJob::Base.queue_adapter = :test
      expect {
        CreateLocalTweetsJob.perform_later(local_batch_job.id, [1,2,3])
      }.to have_enqueued_job
    end
  end

  describe "#perform_now" do
    it "creates local tweets" do
      tweet_ids = [1,2,3]
      CreateLocalTweetsJob.perform_now(local_batch_job.id, tweet_ids)
      expect(local_batch_job.local_tweets.count).to eq(tweet_ids.length)
    end

    it "creates local tweets by first removing old ones" do
      expect(local_batch_job2.local_tweets.count).to eq(2)
      tweet_ids = [1,2,3]
      CreateLocalTweetsJob.perform_now(local_batch_job2.id, tweet_ids, destroy_first: true)
      expect(local_batch_job2.local_tweets.count).to eq(tweet_ids.length)
    end
  end
end
