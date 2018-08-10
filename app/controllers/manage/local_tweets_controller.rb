module Manage
  class LocalTweetsController < BaseController
    def index
      @local_batch_job = LocalBatchJob.friendly.find(params[:manage_local_batch_job_id])
      @local_tweets = @local_batch_job.local_tweets.page params[:page]
    end
  end
end
