module Manage
  class LocalBatchJobsController < BaseController
    load_and_authorize_resource :find_by => :slug

    def index
      @local_batch_jobs = LocalBatchJob.all.order('created_at DESC').page(params[:page]).per(10)
    end

    def new
    end

    def edit
    end

    def update
      if @local_batch_job.update_attributes(local_batch_job_params)
        if @local_batch_job.job_file.present?
          tweet_rows = CSV.foreach(@local_batch_job.job_file.path).map{ |row| row }
          CreateLocalTweetsJob.perform_later(@local_batch_job.id, tweet_rows, destroy_first: true)
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
          CreateLocalTweetsJob.perform_later(@local_batch_job.id, tweet_rows)
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

    def local_batch_job_params
      params.require(:local_batch_job).permit(:name, :project_id, :job_file, :instructions, :user_ids => [])
    end
  end
end
