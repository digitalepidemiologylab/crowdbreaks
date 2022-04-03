module Manage
  class MturkBatchJobsController < BaseController
    load_and_authorize_resource

    def new; end

    def index
      @mturk_batch_jobs = MturkBatchJob.all.order('created_at DESC').page(params[:page]).per(10)
      flash[:notice] = 'The requested file is now ready to download' if params[:requested_download_complete].present?
    end

    def show
      type = 'mturk-batch-job-results'
      respond_to do |format|
        format.html
        format.csv {
          redirect_to @mturk_batch_job.assoc_signed_file_path(type, @mturk_batch_job.results)
        }
        format.js {
          ActionCable.server.broadcast("job_notification:#{current_user.id}", job_status: 'running', record_id: @mturk_batch_job.id, job_type: "#{type}_s3_upload", message: 'Upload started.')
          S3UploadJob.perform_later(type, @mturk_batch_job.id, current_user.id)
          head :ok
        }
      end
    end

    def edit; end

    def update
      render :edit and return unless @mturk_batch_job.update_attributes(mturk_batch_job_params)

      if @mturk_batch_job.job_file.present?
        # only overwrite if file was provided
        CreateTasksJob.perform_later(@mturk_batch_job.id, @mturk_batch_job.retrieve_tweet_rows, destroy_first: true)
      end
      redirect_to(mturk_batch_jobs_path, notice: "Job '#{@mturk_batch_job.name}' is being updated...")
    end

    def create
      @mturk_batch_job.sanitize_keywords!
      render :new and return unless @mturk_batch_job.save

      # generate tasks
      CreateTasksJob.perform_later(@mturk_batch_job.id, @mturk_batch_job.retrieve_tweet_rows)
      redirect_to(mturk_batch_jobs_path, notice: "Job '#{@mturk_batch_job.name}' is being created...")
    end

    def destroy
      redirect_to(mturk_batch_jobs_path, notice: 'Job could not be found.') unless @mturk_batch_job.present?
      destroy_results = false
      destroy_results = params[:destroy_results] == 'true' if params[:destroy_results].present?
      DestroyMturkBatchJob.perform_later(@mturk_batch_job.id, destroy_results: destroy_results)
      redirect_to(mturk_batch_jobs_path, notice: "Job '#{@mturk_batch_job.name}' is being destroyed...")
    end

    def submit
      if @mturk_batch_job.status != 'unsubmitted'
        redirect_to(mturk_batch_jobs_path, alert: "Batch must be in 'unsubmitted' stated in order to be submitted.")
        return
      end

      SubmitTasksJob.perform_later(@mturk_batch_job.id)
      redirect_to(mturk_batch_jobs_path, notice: "HITs for batch #{@mturk_batch_job.name} are being submitted...")
    end

    def clone
      mturk_batch_job_clone = MturkBatchJob.find(params[:clone_id])
      cloned_attributes = mturk_batch_job_clone.attributes.select { |a|
        %w[name project_id description title keywords reward lifetime_in_seconds auto_approval_delay_in_seconds
           assignment_duration_in_seconds instructions number_of_assignments minimal_approval_rate max_tasks_per_worker
           exclude_blacklisted check_availability min_num_hits_approved delay_start delay_next_question sandbox].include?(a)
      }
      @mturk_batch_job = MturkBatchJob.new(cloned_attributes)
      @mturk_batch_job.cloned_name = @mturk_batch_job.name
      @mturk_batch_job.name = "#{@mturk_batch_job.name}-copy"
      render :clone
    end

    private

    def mturk_batch_job_params
      params.require(:mturk_batch_job).permit(
        :name, :title, :description, :keywords, :project_id, :number_of_assignments, :job_file, :reward,
        :lifetime_in_seconds, :auto_approval_delay_in_seconds, :assignment_duration_in_seconds, :sandbox,
        :instructions, :minimal_approval_rate, :max_tasks_per_worker, :check_availability, :exclude_blacklisted,
        :min_num_hits_approved, :delay_start, :delay_next_question, :existing_qualification_type_id,
        :mturk_worker_qualification_list_id
      )
    end
  end
end
