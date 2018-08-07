module Manage
  class LocalBatchJobsController < BaseController
    def index
      @local_batch_jobs = LocalBatchJob.all.order('created_at DESC').page(params[:page]).per(10)
    end

    def new
      @local_batch_job = LocalBatchJob.new
    end

    def show
      @local_batch_job = LocalBatchJob.friendly.find(params[:id])
    end

    def edit
      @local_batch_job = LocalBatchJob.friendly.find(params[:id])
    end

    def update
      @local_batch_job = LocalBatchJob.friendly.find(params[:id])
      if @local_batch_job.update_attributes(batch_params)
        if @local_batch_job.job_file.present?
          tweet_ids = CSV.foreach(@local_batch_job.job_file.path).map{ |row| row[0] }
          CreateLocalTweetsJob.perform_later(@local_batch_job.id, tweet_ids, destroy_first: true)
        end
        redirect_to(local_batch_jobs_path, notice: "Job '#{@local_batch_job.name}' is being updated...")
      else
        render :edit and return
      end
    end

    def create
      @local_batch_job = LocalBatchJob.new(batch_params)
      if @local_batch_job.save
        if @local_batch_job.job_file.present?
          tweet_ids = CSV.foreach(@local_batch_job.job_file.path).map{ |row| row[0] }
          CreateLocalTweetsJob.perform_later(@local_batch_job.id, tweet_ids)
        end
        redirect_to(local_batch_jobs_path, notice: "Job '#{@local_batch_job.name}' is being created...")
      else
        render :new and return
      end
    end

    def destroy
      @local_batch_job = LocalBatchJob.friendly.find(params[:id])
      unless @local_batch_job.present?
        redirect_to(local_batch_jobs_path, notice: "Job '#{@local_batch_job.name}' could not be found.")
      end
      DestroyLocalBatchJob.perform_later(@local_batch_job.id)
      redirect_to(local_batch_jobs_path, notice: "Job '#{@local_batch_job.name}' is being destroyed...")
    end


    private

    def batch_params
      params.require(:local_batch_job).permit(:name, :project_id, :job_file, :instructions, :user_ids => [])
    end
  end
end
