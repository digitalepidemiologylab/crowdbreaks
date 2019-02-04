module Manage
  class TasksController < BaseController
    load_and_authorize_resource :mturk_batch_job
    load_and_authorize_resource :task, through: :mturk_batch_job

    def new
    end

    def index
      @show_unsubmitted = param_is_truthy?(:show_unsubmitted, default: true)
      @show_submitted = param_is_truthy?(:show_submitted, default: true)
      @show_assigned = param_is_truthy?(:show_assigned, default: true)
      @show_completed = param_is_truthy?(:show_completed, default: true)
      statuses = []
      statuses.push(:unsubmitted) if @show_unsubmitted
      statuses.push(:submitted) if @show_submitted
      statuses.push(:assigned) if @show_assigned
      statuses.push(:completed) if @show_completed
      @tasks = @tasks.where(lifecycle_status: statuses).order({lifecycle_status: :asc, updated_at: :desc}).page params[:page]
    end

    def show
    end

    def create
    end

    def edit
    end

    def update
      if @task.update_attributes(task_params)
        flash[:notice] = 'Task successfully updated!'
      else
        flash[:alert] = 'Editing task was unsuccessful'
      end
      redirect_to mturk_batch_job_tasks_path
    end

    def destroy
      @task.delete_hit
      # to be implemented...
      redirect_to mturk_batch_job_tasks_path
    end

    private

    def task_params
      params.require(:task).permit(:tweet_id, :hit_id)
    end
  end
end
