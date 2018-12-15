require 'rails_helper'

RSpec.describe MturkBatchJobS3UploadJob, type: :job do
  let!(:mturk_batch_job) { FactoryBot.create(:mturk_batch_job, number_of_assignments: 2) }
  let!(:user) { FactoryBot.create(:user) }

  describe "#perform_later" do
    it "enqueues a job" do
      ActiveJob::Base.queue_adapter = :test
      expect {
        MturkBatchJobS3UploadJob.perform_later(mturk_batch_job.id, user.id)
      }.to have_enqueued_job
    end
  end

  describe "#perform_now" do
    it "tries to upload to s3" do
      MturkBatchJobS3UploadJob.perform_now(mturk_batch_job.id, user.id)
      aws_s3_url = /https:\/\/crowdbreaks-dev.s3.eu-central-1.amazonaws.com(.*)/
      assert_requested :any, aws_s3_url
    end
  end
end
