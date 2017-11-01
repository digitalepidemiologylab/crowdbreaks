module Manage
  class TasksController < BaseController
    def new
    end

    def index
      if params[:mturk_batch_job_id]
        @mturk_batch_job = MturkBatchJob.find_by(id: params[:mturk_batch_job_id])
        @tasks = @mturk_batch_job.tasks.page params[:page]
      else
        @mturk_batch_job = nil
        @tasks = Task.all
      end
    end

    def show
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
      redirect_to manage_mturk_batch_job_tasks_path
    end

    def destroy
      @task = Task.find_by(id: params[:id])
      @task.destroy
      redirect_to manage_mturk_batch_job_tasks_path
    end

    private

    def task_params
      params.require(:task).permit(:tweet_id, :hit_id)
    end
  end
end
