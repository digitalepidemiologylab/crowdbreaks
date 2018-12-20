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

    def review
      @mturk_worker = MturkWorker.find_by(id: params[:mturk_worker_id])
      @selected_batch_job = params[:batch_name_filter]
      qs = @mturk_worker.results
      qs = qs
        .left_outer_joins(:task)
        .select('MAX(results.id) as id', 'MAX(results.created_at) as created_at', 'count(*) as num_results', :project_id, :tweet_id, :task_id, 'tasks.mturk_batch_job_id as mturk_batch_job_id')
        .group(:project_id, :tweet_id, 'tasks.mturk_batch_job_id', :task_id)
        .order(Arel.sql('max(results.created_at) DESC'))
      @mturk_batch_jobs_by_worker = MturkBatchJob.where(id: qs.pluck('tasks.mturk_batch_job_id').uniq).pluck(:name)
      if @selected_batch_job.present?
        mturk_batch_job = MturkBatchJob.find_by(name: @selected_batch_job)
        qs = qs.where('tasks.mturk_batch_job_id': mturk_batch_job.id)
      end
      @num_qs = qs.length
      @qs = qs.page params[:page]
      tt = MturkTweet.where(tweet_id: @qs.pluck(:tweet_id)).pluck(:tweet_id, :tweet_text)
      @tweet_texts = {}
      tt.each do |tweet| 
        @tweet_texts[tweet[0]] = tweet[1]
      end
      @tasks = {}
      @qs_results = {}
      @logs = {}
      @mturk_cached_hit = {}
      @qs.each do |question_sequence|
        res = Result.find_by(id: question_sequence.id)
        if res.present?
          @tasks[res.id] = res.task
          results = Result.where(task_id: question_sequence.task_id).order(created_at: :asc)
          @qs_results[res.id] = results
          @logs[res.id] = Hashie::Mash.new results&.first&.question_sequence_log&.log
          @mturk_cached_hit[res.id] = MturkCachedHit.find_by(hit_id: res.task&.hit_id)
        end
      end
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

    def get_qs(tweet_id, project_id, task_id)
    end
  end
end
