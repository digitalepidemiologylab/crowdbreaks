module Manage
  class LocalBatchJobsController < BaseController
    load_and_authorize_resource param_method: :sanitized_local_batch_job_params, :find_by => :slug

    def index
      @local_batch_jobs = @local_batch_jobs.order('created_at DESC').page(params[:page]).per(10)
    end

    def new
    end

    def show
      type = 'local-batch-job-results'
      respond_to do |format|
        format.html {
          @counts = []
          @local_batch_job.users.each do |user|
            @counts.push({
              'count': @local_batch_job.results.group_by_qs.where(user_id: user.id).length,
              'username': user.username,
            })
          end
          @num_tweets = @local_batch_job.local_tweets.count
        }
        format.csv {
          redirect_to @local_batch_job.assoc_signed_file_path(type, @local_batch_job.results)
        }
        format.js {
          ActionCable.server.broadcast("job_notification:#{current_user.id}", job_status: 'running', record_id: @local_batch_job.id, job_type: "#{type}_s3_upload", message: 'Upload started.')
          S3UploadJob.perform_later(type, @local_batch_job.id, current_user.id)
          head :ok
        }
      end
    end

    def edit
    end

    def update
      if @local_batch_job.update_attributes(sanitized_local_batch_job_params)
        if @local_batch_job.job_file.present?
          tweet_rows = CSV.foreach(@local_batch_job.job_file.path).map{ |row| row }
          CreateLocalTweetsJob.perform_later(@local_batch_job.id, current_user.id, tweet_rows, destroy_first: true)
        end
        redirect_to(manage_local_batch_jobs_path, notice: "Job '#{@local_batch_job.name}' is being updated...")
      else
        render :edit and return
      end
    end

    def create
      if @local_batch_job.save
        if @local_batch_job.job_file.present?
          tweet_rows = CSV.foreach(@local_batch_job.job_file.path).map{ |row| row }
          CreateLocalTweetsJob.perform_later(@local_batch_job.id, current_user.id, tweet_rows)
        end
        redirect_to(manage_local_batch_jobs_path, notice: "Job '#{@local_batch_job.name}' is being created...")
      else
        render :new and return
      end
    end

    def destroy
      unless @local_batch_job.present?
        redirect_to(manage_local_batch_jobs_path, notice: "Job '#{@local_batch_job.name}' could not be found.")
      end
      DestroyLocalBatchJob.perform_later(@local_batch_job.id)
      redirect_to(manage_local_batch_jobs_path, notice: "Job '#{@local_batch_job.name}' is being destroyed...")
    end


    private

    def sanitized_local_batch_job_params
      sanitized_params = local_batch_job_params
      sanitized_params[:processing_mode] = sanitized_params[:processing_mode].to_i
      sanitized_params[:annotation_display_mode] = sanitized_params[:annotation_display_mode].to_i
      sanitized_params
    end

    def local_batch_job_params
      params.require(:local_batch_job).permit(:name, :project_id, :job_file, :instructions, :processing_mode, :check_availability, :tweet_display_mode, :delay_start, :delay_next_question, :annotation_display_mode, :user_ids => [])
    end
  end
end
