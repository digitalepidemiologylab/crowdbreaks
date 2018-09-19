require 'rails_helper'

RSpec.describe CreateTasksJob, type: :job do
  let!(:mturk_batch_job) { FactoryBot.create(:mturk_batch_job, number_of_assignments: 2) }

  describe "#perform_later" do
    it "enqueues a job" do
      ActiveJob::Base.queue_adapter = :test
      expect {
        CreateTasksJob.perform_later(mturk_batch_job.id, [1,2,3])
      }.to have_enqueued_job
    end
  end

  describe "#perform_now" do
    it "creates tasks and mturk_tweets" do
      tweet_ids = [[1],[2],[3]]
      CreateTasksJob.perform_now(mturk_batch_job.id, tweet_ids)
      expect(mturk_batch_job.tasks.count).to eq(mturk_batch_job.number_of_assignments * tweet_ids.length)
      expect(mturk_batch_job.mturk_tweets.count).to eq(tweet_ids.length)
    end

    it "creates mturk_tweets with text" do
      expect(mturk_batch_job.mturk_tweets.count).to eq(0)
      tweet_ids = [[1, 'first tweet'],[2, 'second tweet'],[3]]
      CreateTasksJob.perform_now(mturk_batch_job.id, tweet_ids, destroy_first: true)
      expect(mturk_batch_job.mturk_tweets.count).to eq(tweet_ids.length)
      expect(mturk_batch_job.mturk_tweets.first.tweet_text).to_not eq("")
      expect(mturk_batch_job.mturk_tweets.second.tweet_text).to_not eq("")
      # for third tweet no text was provided
      expect(mturk_batch_job.mturk_tweets.third.tweet_text).to eq("")
    end
  end
end
