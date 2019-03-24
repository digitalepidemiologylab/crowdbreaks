module Manage
  class LocalTweetsController < BaseController
    load_and_authorize_resource :local_batch_job, find_by: :slug, id_param: :manage_local_batch_job_id
    load_and_authorize_resource :local_tweet, through: :local_batch_job

    def index
      type = 'local-batch-job-tweets'
      respond_to do |format|
        format.html {
          @download_link_args = [manage_local_batch_job_local_tweets_path(@local_batch_job)]
          @download_link_keywordargs = {remote: true}
          if @local_batch_job.csv_file_is_up_to_date(type, @local_batch_job.local_tweets)
            @download_link_args = [manage_local_batch_job_local_tweets_path(@local_batch_job, format: :csv)]
            @download_link_keywordargs = {}
          end
          @local_tweets = @local_tweets.page params[:page]
        }
        format.csv { 
          redirect_to @local_batch_job.signed_csv_file_path(type, @local_batch_job.local_tweets)
        }
        format.js {
          ActionCable.server.broadcast("job_notification:#{current_user.id}", job_status: 'running', record_id: @local_batch_job.id, job_type: "#{type}_s3_upload", message: 'Upload started.')
          S3UploadJob.perform_later(type, @local_batch_job.id, current_user.id)
          head :ok
        }
      end
    end
  end
end
