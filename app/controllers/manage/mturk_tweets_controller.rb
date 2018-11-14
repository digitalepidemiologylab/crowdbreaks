module Manage
  class MturkTweetsController < BaseController
    def index
      @mturk_batch_job = MturkBatchJob.find_by(id: params[:mturk_batch_job_id])
      @mturk_tweets = @mturk_batch_job.mturk_tweets.page params[:page]
    end

    def update_availability
      if current_user
        RefreshMturkTweetsAvailabilityJob.perform_later(params[:mturk_batch_job_id], current_user.id)
        respond_to do |format|
          format.js { head :ok }
        end
      else
        respond_to do |format|
          format.js { head :bad_request }
        end
      end
    end
  end
end
