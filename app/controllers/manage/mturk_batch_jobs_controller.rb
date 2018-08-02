require 'csv'

module Manage
  class MturkBatchJobsController < BaseController
    def new
      @mturk_batch_job = MturkBatchJob.new
    end

    def index
      @mturk_batch_jobs = MturkBatchJob.all.order('created_at DESC').page(params[:page]).per(10)
    end

    def show
      @mturk_batch_job = MturkBatchJob.find_by(id: params[:id])
    end

    def edit
      @mturk_batch_job = MturkBatchJob.find_by(id: params[:id])
      @is_submitted = @mturk_batch_job.is_submitted?
    end

    def update
      @mturk_batch_job = MturkBatchJob.find_by(id: params[:id])
      respond_to do |format|
        if @mturk_batch_job.update_attributes(batch_params)
          # generate tasks
          if @mturk_batch_job.job_file.present?
            if file_valid?
              tweet_ids = CSV.foreach(@mturk_batch_job.job_file.path).map{|row| row[0]}
              CreateTasksJob.perform_now(@mturk_batch_job.id, tweet_ids, destroy_first: true)
            else
              render :edit and return
            end
          end
          format.html { redirect_to(mturk_batch_jobs_path, notice: "Job '#{@mturk_batch_job.name}' is being updated...")}
        else
          format.html { redirect_to(mturk_batch_jobs_path, alert: 'Something went wrong when updating the Mturk Batch Job')}
        end
      end
    end

    def create
      @mturk_batch_job = MturkBatchJob.new(batch_params)
      if @mturk_batch_job.job_file.present? and not file_valid?
        render :new and return
      end
      if @mturk_batch_job.save
        tweet_ids = CSV.foreach(@mturk_batch_job.job_file.path).map{|row| row[0]}
        CreateTasksJob.perform_later(@mturk_batch_job.id, tweet_ids)
        redirect_to(mturk_batch_jobs_path, notice: "Job '#{@mturk_batch_job.name}' is being created...")
      else
        render :new 
      end
    end

    def destroy
      @mturk_batch_job = MturkBatchJob.find_by(id: params[:id])
      unless @mturk_batch_job.present?
        redirect_to(mturk_batch_jobs_path, notice: "Job '#{@mturk_batch_job.name}' could not be found.")
      end
      DestroyMturkBatchJob.perform_later(@mturk_batch_job.id)
      redirect_to(mturk_batch_jobs_path, notice: "Job '#{@mturk_batch_job.name}' is being destroyed...")
    end

    def submit
      mturk_batch_job = MturkBatchJob.find_by(id: params[:mturk_batch_job_id])
      if mturk_batch_job.status != 'unsubmitted'
        redirect_to(mturk_batch_job_tasks_path(params[:mturk_batch_job_id]), danger: "Batch must be in 'unsubmitted' stated in order to be submitted.")
        return
      end

      SubmitTasksJob.perform_later(mturk_batch_job.id)
      redirect_to(mturk_batch_jobs_path, notice: "HITs for batch #{mturk_batch_job.name} are being submitted...")
    end

    private


    def batch_params
      params.require(:mturk_batch_job).permit(:name, :title, :description, :keywords, :project_id, :number_of_assignments, :job_file, :reward, :lifetime_in_seconds, :auto_approval_delay_in_seconds, :assignment_duration_in_seconds, :sandbox, :instructions)
    end

    def file_valid?
      csv_file = @mturk_batch_job.job_file
      if csv_file.content_type != 'text/csv'
        @mturk_batch_job.errors.add(:job_file, 'File format has to be csv')
        return false
      end

      if @mturk_batch_job.number_of_assignments.to_i == 0 or @mturk_batch_job.number_of_assignments.to_i > 100
        @mturk_batch_job.errors.add(:number_of_assignments, 'Number assignments cannot be 0 or >100')
        return false
      end

      if CSV.table(csv_file.path, {headers: false}).count == 0
        @mturk_batch_job.errors.add(:job_file, 'Unsuccessful. File was empty.')
        return false
      end

      if not file_content_valid?
        @mturk_batch_job.errors.add(:job_file, 'One or more tweet IDs were invalid integers.')
        return false
      end
      return true
    end

    def file_content_valid?
      CSV.foreach(@mturk_batch_job.job_file.path) do |line|
        tweet_id = line[0].to_s
        if not tweet_id =~ /\A\d{1,}\z/
          return false
        end
      end
      return true
    end
  end
end
