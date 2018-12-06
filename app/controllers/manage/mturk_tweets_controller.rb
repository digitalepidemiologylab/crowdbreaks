module Manage
  class MturkTweetsController < BaseController
    load_and_authorize_resource :mturk_batch_job
    load_and_authorize_resource :mturk_tweet, through: :mturk_batch_job

    def index
      respond_to do |format|
        format.html {
          @mturk_tweets = @mturk_batch_job.mturk_tweets.page params[:page]
        }
        format.csv {
          redirect_to @mturk_batch_job.signed_csv_file_path('tweets')
        }
        format.js {
          ActionCable.server.broadcast("job_notification:#{current_user.id}", job_status: 'running', mturk_batch_job_id: @mturk_batch_job.id, job_type: 'mturk_tweets_job_s3_upload', message: 'Upload started.')
          MturkTweetsS3UploadJob.perform_later(@mturk_batch_job.id, current_user.id)
          head :ok
        }
      end
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
