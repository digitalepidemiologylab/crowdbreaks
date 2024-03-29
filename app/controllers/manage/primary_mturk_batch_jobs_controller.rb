module Manage
  class PrimaryMturkBatchJobsController < BaseController
    include Response

    before_action :set_primary_mturk_batch_job, only: %i[edit update destroy]

    # There's not gonna be an index page for that, it will be shown in MturkAutoController
    def index; end

    # Also in MturkAutoController
    def new; end

    # Should be automatic after creating a project
    # nullable, only read for the projects that have mturk_auto: true
    def create; end

    # The form from MturkAutoController should come in here
    # OR put this method directly to MturkAutoController
    def update
      authorize! :update, :mturk_auto
      if @primary_mturk_batch_job.update(primary_job_params)
        respond_with_flash(
          Helpers::ApiResponse.new(
            status: :success,
            message: "Successfully updated primary job for project #{@primary_mturk_batch_job.project.name}."
          ), mturk_auto_path
        )
      else
        respond_with_flash(
          Helpers::ApiResponse.new(
            status: :fail, message: "Failed to update primary job for project #{@primary_mturk_batch_job.project.name}."
          ), mturk_auto_path
        )
      end
    end

    # Should be automatically destroyed upon destroying the corresponding mturk batch job
    def destroy; end

    private

    def set_primary_mturk_batch_job
      @primary_mturk_batch_job = PrimaryMturkBatchJob.find(params[:id])
    end

    def primary_job_params
      params.require(:primary_mturk_batch_job).permit(
        :mturk_batch_job_id, :max_tasks_per_worker, :mturk_worker_qualification_list_id
      )
    end
  end
end
