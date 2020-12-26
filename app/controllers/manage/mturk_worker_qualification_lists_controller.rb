module Manage
  class MturkWorkerQualificationListsController < BaseController
    load_and_authorize_resource

    def new
    end

    def index
      @mturk_worker_qualification_lists = @mturk_worker_qualification_lists.order('created_at DESC').page(params[:page]).per(10)
    end

    def show
    end

    def create
      if @mturk_worker_qualification_list.save
        @mturk_worker_qualification_list.updating_status!
        CreateMturkWorkerQualificationListJob.perform_later(@mturk_worker_qualification_list.id, @mturk_worker_qualification_list.retrieve_tweet_rows)
        redirect_to(mturk_worker_qualification_lists_path, notice: "Qaulification list '#{@mturk_worker_qualification_list.name}' is being created...")
      else
        render :new and return
      end
    end

    def edit
    end

    def update
      if @mturk_worker_qualification_list.update_attributes(mturk_worker_qualification_list_params)
        if @mturk_worker_qualification_list.job_file.present?
          @mturk_worker_qualification_list.updating_status!
          CreateMturkWorkerQualificationListJob.perform_later(@mturk_worker_qualification_list.id, @mturk_worker_qualification_list.retrieve_tweet_rows, destroy_first: true)
        end
        redirect_to(mturk_worker_qualification_lists_path, notice: "Qaulification list '#{@mturk_worker_qualification_list.name}' is being created...") and return
      else
        render :new and return
      end
    end

    def destroy
      if @mturk_worker_qualification_list.mturk_batch_jobs.any?
        redirect_to(mturk_worker_qualification_lists_path, alert: "Qaulification list '#{@mturk_worker_qualification_list.name}' is still referenced in batch jobs. Cannot delete.") and return
      end
      @mturk_worker_qualification_list.deleting_status!
      DestroyMturkWorkerQualificationListJob.perform_later(@mturk_worker_qualification_list.id)
      redirect_to(mturk_worker_qualification_lists_path, notice: "Qaulification list '#{@mturk_worker_qualification_list.name}' is being destroyed...") and return
    end

    private

    def mturk_worker_qualification_list_params
      params.require(:mturk_worker_qualification_list).permit(:name, :description, :job_file, :sandbox)
    end

  end
end
