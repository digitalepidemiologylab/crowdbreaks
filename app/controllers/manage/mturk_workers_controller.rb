module Manage
  class MturkWorkersController < BaseController
    load_and_authorize_resource

    def index
      @show_blacklisted = param_is_truthy?(:show_blacklisted)
      @show_reviewed = param_is_truthy?(:show_reviewed)
      @show_blocked = param_is_truthy?(:show_blocked)
      query = @mturk_workers.joins(:tasks).select('MAX(tasks.updated_at) as last_task_created', :id, :worker_id, :status, :created_at, :manually_reviewed).group('mturk_workers.id')
      if @show_blacklisted
        query = query.blacklisted_status
      end
      if @show_blocked
        query = query.blocked_status
      end
      if @show_reviewed
        query = query.where(manually_reviewed: true)
      end
      if params[:search_worker].present?
        query = query.where('worker_id LIKE ?', "%#{params[:search_worker]}%").page params[:page]
      else
        query = query.page params[:page]
      end
      @mturk_workers = query.order('last_task_created DESC')
    end

    def review
      @selected_batch_job = params[:batch_name_filter]
      qs = @mturk_worker.results
      qs = qs.group_by_qs_mturk.order(Arel.sql('max(results.created_at) DESC'))
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
          all_reviewed = results.pluck(:manual_review_status).uniq == ['reviewed']
          @qs_results[res.id] = {'results': results, 'all_reviewed': all_reviewed}
          @logs[res.id] = Hashie::Mash.new results&.first&.question_sequence_log&.log
          @mturk_cached_hit[res.id] = MturkCachedHit.find_by(hit_id: res.task&.hit_id)
        end
      end
      @default_approve_message = Mturk::DEFAULT_ACCEPT_MESSAGE
      @default_reject_message = Mturk::DEFAULT_REJECT_MESSAGE
    end

    def blacklist
      if @mturk_worker.present?
        if not @mturk_worker.blacklisted_status?
          @mturk_worker.blacklisted_status!
          redirect_after_update(notice: 'Successfully blacklisted worker!')
        else
          @mturk_worker.default_status!
          redirect_after_update(notice: 'Successfully un-blacklisted worker!')
        end
      else
        redirect_after_update(alert: 'Could not find worker.')
      end
    end

    def block
      if @mturk_worker.present?
        if @mturk_worker.blocked_status?
          if @mturk_worker.unblock
            @mturk_worker.default_status!
            redirect_after_update(notice: 'Successfully un-blocked worker!')
          else
            redirect_after_update(alert: 'Something went wrong when trying to un-block worker.')
          end
        else
          if @mturk_worker.block(block_params[:reason])
            @mturk_worker.blocked_status!
            redirect_after_update(notice: 'Successfully blocked worker!')
          else
            redirect_after_update(alert: 'Something went wrong when trying to block worker.')
          end
        end
      else
        redirect_after_update(alert: 'Could not find worker.')
      end
    end

    def submit_block
      @show_blacklisted = param_is_truthy?(:show_blacklisted)
      @show_reviewed = param_is_truthy?(:show_reviewed)
      @show_blocked = param_is_truthy?(:show_blocked)
      @default_reason = Mturk::DEFAULT_BLOCK_REASON
    end

    def manual_review_status
      if @mturk_worker.present?
        if not @mturk_worker.manually_reviewed?
          @mturk_worker.results.each do |result|
            result.reviewed_manual_review_status!
          end
          @mturk_worker.update_attribute(:manually_reviewed, true)
          redirect_after_update(notice: 'Successfully set results by this worker to reviewed')
        else
          @mturk_worker.results.each do |result|
            result.unreviewed_manual_review_status!
          end
          @mturk_worker.update_attribute(:manually_reviewed, false)
          redirect_after_update(notice: 'Successfully set results by this worker to unreviewed')
        end
      else
        redirect_after_update(alert: 'Could not find worker.')
      end
    end

    def review_assignment
      mturk = Mturk.new(sandbox: false)
      if review_params[:accept]
        mturk.approve_assignment(review_params[:assignment_id], message: review_params[:message])
      else
        mturk.reject_assignment(review_params[:assignment_id], message: review_params[:message])
      end
    end

    def refresh_review_status
      if params[:hit_id].empty?
        render nothing: true, status: :bad_request and return
      end
      mturk = Mturk.new(sandbox: false)
      assignment = mturk.list_assignments_for_hit(params[:hit_id])&.assignments&.first&.to_h
      render json: assignment.to_json, status: 200
    end


    private

    def redirect_after_update(notice: '', alert: '')
      @show_blacklisted = param_is_truthy?(:show_blacklisted)
      p @show_blacklisted
      p params
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

    def review_params
      params.require(:review).permit(:message, :assignment_id, :accept)  
    end

    def block_params
      params.require(:block).permit(:reason)  
    end
  end
end
