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
    end

    def edit
      @mturk_batch_job = MturkBatchJob.find_by(id: params[:id])
      @is_submitted = @mturk_batch_job.status != :unsubmitted
    end

    def update
      @mturk_batch_job = MturkBatchJob.find_by(id: params[:id])
      respond_to do |format|
        if @mturk_batch_job.update_attributes(batch_params)
          # generate tasks
          if @mturk_batch_job.job_file.present?
            if file_valid?
              @mturk_batch_job.tasks.destroy_all
              generate_tasks_from_csv
            else
              render :edit and return
            end
          end
          format.html { redirect_to(mturk_batch_jobs_path, notice: 'Mturk batch job successfully updated.')}
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
        if @mturk_batch_job.job_file.present?
          generate_tasks_from_csv
        end
        respond_to do |format|
          format.html { redirect_to(mturk_batch_jobs_path, notice: 'Job successfully created')}
        end
      else
        respond_to do |format|
          format.html { 
            render :new 
          }
        end
      end
    end

    def destroy
      @mturk_batch_jobs = MturkBatchJob.find_by(id: params[:id])
      @mturk_batch_jobs.destroy
      redirect_to mturk_batch_jobs_path
    end

    def submit
      batch_job = MturkBatchJob.find_by(id: params[:mturk_batch_job_id])
      tasks = batch_job.tasks.where(lifecycle_status: :unsubmitted)
      if tasks.size == 0
        flash[:danger] = "There are no tasks available to submit in this batch."
        redirect_to mturk_batch_job_tasks_path(params[:mturk_batch_job_id])
        return
      end

      # initialize requester and props
      requester, props = batch_job.mturk_init

      # submit jobs, create hits
      submit_status = []
      tasks.each do |t|
        status = t.submit_job(requester, props)
        submit_status.push(status)
      end

      flash[:notice] = "Submitted #{submit_status.count(true)}/#{tasks.size} tasks successfully."
      redirect_to mturk_batch_job_tasks_path(params[:mturk_batch_job_id])
    end

    private

    def batch_params
      params.require(:mturk_batch_job).permit(:name, :title, :description, :keywords, :project_id, :number_of_assignments, :job_file, :reward, :lifetime_in_seconds, :auto_approval_delay_in_seconds, :assignment_duration_in_seconds, :sandbox, :instructions)
    end


    def generate_tasks_from_csv
      if not @mturk_batch_job.id.present?
        Rails.logger.error("Mturk batch job ID not available, cannot create tasks.")
      end
      CSV.foreach(@mturk_batch_job.job_file.path) do |line|
        tweet_id = line[0].to_s
        num_assignments = @mturk_batch_job.number_of_assignments.to_i
        num_assignments.times do 
          Task.create(tweet_id: tweet_id, mturk_batch_job_id: @mturk_batch_job.id)
        end
      end
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
