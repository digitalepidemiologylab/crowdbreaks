module Manage
  class MturkWorkersController < BaseController
    load_and_authorize_resource

    def index
      @show_blacklisted = param_is_truthy?(:show_blacklisted)
      query = MturkWorker.joins(:tasks).select('MAX(tasks.created_at) as last_task_created', :id, :worker_id, :status, :created_at).group('mturk_workers.id')
      if @show_blacklisted
        query = query.blacklisted_status
      end

      if params[:search_worker].present?
        query = query.where('worker_id LIKE ?', "%#{params[:search_worker]}%").page params[:page]
      else
        query = query.page params[:page]
      end
      @mturk_workers = query.order('last_task_created DESC')
    end

    def blacklist
      mturk_worker = MturkWorker.find_by(id: params[:mturk_worker_id])
      if mturk_worker.present?
        if not mturk_worker.blacklisted_status?
          mturk_worker.blacklisted_status!
          redirect_after_blacklist(notice: 'Successfully blacklisted worker!')
        else
          mturk_worker.default_status!
          redirect_after_blacklist(notice: 'Successfully un-blacklisted worker!')
        end
      else
        redirect_after_blacklist(alert: 'Could not find worker.')
      end
    end


    private

    def redirect_after_blacklist(notice: '', alert: '')
      @show_blacklisted = param_is_truthy?(:show_blacklisted)
      pass_params = {search_worker: params[:search_worker], show_blacklisted: @show_blacklisted}
      if notice.present?
        redirect_to mturk_workers_path(**pass_params), notice: notice
      elsif alert.present?
        redirect_to mturk_workers_path(**pass_params), alert: alert
      else
        redirect_to mturk_workers_path(**pass_params)
      end
    end
  end
end
