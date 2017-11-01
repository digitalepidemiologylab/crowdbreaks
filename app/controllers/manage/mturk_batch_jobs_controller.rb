module Manage
  class MturkBatchJobsController < BaseController
    def new
      @mturk_batch_job = MturkBatchJob.new
    end

    def index
      @mturk_batch_jobs = MturkBatchJob.all
    end

    def show
    end


    def create
      @mturk_batch_job = MturkBatchJob.new(batch_params)

      respond_to do |format|
        if @mturk_batch_job.save
          format.html { redirect_to(manage_mturk_batch_jobs_path, notice: 'Job successfully created')}
        else
          format.html { render :new }
        end
      end

    end


    private

    def batch_params
      params.require(:mturk_batch_job).permit(:name, :sandbox)
    end
  end
end
