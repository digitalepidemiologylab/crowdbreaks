module Manage
  class TasksController < BaseController
    def new
    end

    def index
      @mturk_batch_job = MturkBatchJob.find_by(id: params[:mturk_batch_job_id])
      @tasks = @mturk_batch_job.tasks.page params[:page]
    end

    def show
      @task = Task.find(params[:id])
      @hit = @task.hit
    end

    def create
    end

    def edit
      @task = Task.find_by(id: params[:id])
    end

    def update
      @task = Task.find_by(id: params[:id])
      if @task.update_attributes(task_params)
        flash[:notice] = 'Task successfully updated!'
      else
        flash[:alert] = 'Editing task was unsuccessful'
      end
      redirect_to mturk_batch_job_tasks_path
    end

    def destroy
      @task = Task.find_by(id: params[:id])
      @task.delete_hit
      @task.update_attribute(:lifecycle_status, :disposed)
      redirect_to mturk_batch_job_tasks_path
    end

    private

    def task_params
      params.require(:task).permit(:tweet_id, :hit_id)
    end
  end
end
