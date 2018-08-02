module Manage
  class MturkTweetsController < BaseController
    def index
      @mturk_batch_job = MturkBatchJob.find_by(id: params[:mturk_batch_job_id])
      @mturk_tweets = @mturk_batch_job.mturk_tweets.page params[:page]
    end
  end
end
