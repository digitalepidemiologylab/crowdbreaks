module Manage
  class MturkReviewableHitsController < BaseController
    authorize_resource class: false
    before_action :mturk_init

    def index
      @hit_type_id = mturk_reviewable_hit_params[:hit_type_id]
      @show_reviewed = param_bool_val(params[:show_reviewed])
      @show_all = false
      @results_per_page = 30   # max 100
      status = @show_reviewed ? 'Reviewing' : 'Reviewable'
      if not @hit_type_id.present?
        @show_all = true
        hits_list = @mturk.list_reviewable_hits(next_token: params[:next_token], max_results: @results_per_page, status: status)
      else
        @mturk_batch_jobs = MturkBatchJob.where(hittype_id: @hit_type_id)
        hits_list = @mturk.list_reviewable_hits(hit_type_id: @hit_type_id, next_token: mturk_reviewable_hit_params[:next_token], status: status)
      end
      @hits = hits_list[:hits]
      @next_token = hits_list[:next_token]
      @num_hits = hits_list[:num_results]
      @page = mturk_reviewable_hit_params[:page].present? ? mturk_reviewable_hit_params[:page].to_i : 1
      @sandbox = in_sandbox?
    end

    def show
      @assignments = []
      # assume provided param is assignemnt ID
      assignment = @mturk.get_assignment(mturk_reviewable_hit_params[:id])
      if assignment.present?
        @hit_info = Hashie::Mash.new(get_hit_info(assignment.hit.hit_id))
        @assignments.push(assignment.assignment)
      else
        # check if provided param is HIT id
        hit_assignments = @mturk.list_assignments_for_hit(mturk_reviewable_hit_params[:id])
        return if hit_assignments.nil?
        @hit_info = Hashie::Mash.new(get_hit_info(mturk_reviewable_hit_params[:id]))
        hit_assignments.assignments.each do |assignment|
          @assignments.push(assignment)
        end
      end
      @sandbox = in_sandbox?
      @default_accept_message = Mturk::DEFAULT_ACCEPT_MESSAGE
      @default_reject_message = Mturk::DEFAULT_REJECT_MESSAGE
    end

    def multi_review
      accepted = multi_review_params[:accepted_ids]
      if accepted.nil? or accepted.empty?
        redirect_to(mturk_reviewable_hits_path, alert: "No HITs selected for accepting.") and return
      end
      accepted.each do |assignment_id|
        @mturk.approve_assignment(assignment_id)
      end
      redirect_to(mturk_reviewable_hits_path, notice: "Successfully accepted #{accepted.length} HIT(s).") and return
    end

    def link_to_results
      task = Task.find_by(hit_id: params[:hit_id])
      if task.nil? or task.results.count == 0 or task.mturk_worker.nil? or task.mturk_batch_job.nil?
        redirect_back(fallback_location: root_path, notice: 'No results found for this HIT.') and return
      end
      result = task.results.first
      redirect_to(admin_result_path(result.id, project_id: result.project_id, user_id: result.user_id,
                                    tweet_id: result.tweet_id, mturk_worker_id: task.mturk_worker.id,
                                    mturk_batch_job_id: task.mturk_batch_job.id,
                                    res_type: result.res_type, group_by_qs: true))
    end

    def accept
      # note: params[:mturk_reviewable_hit_id] is the HIT assignment Id!
      @mturk.approve_assignment(params[:mturk_reviewable_hit_id], message: review_params[:message])
      redirect_to(mturk_reviewable_hit_path(params[:mturk_reviewable_hit_id]), notice: "Successfully accepted HIT.") and return
    end

    def reject
      @mturk.reject_assignment(params[:mturk_reviewable_hit_id], message: review_params[:message])
      redirect_to(mturk_reviewable_hit_path(params[:mturk_reviewable_hit_id]), notice: "Successfully rejected HIT.") and return
    end


    private

    def mturk_reviewable_hit_params
      params.permit(:id, :hit_type_id, :next_token, :page, :sandbox, :come_from, :locale)
    end

    def multi_review_params
      params.permit(:accepted_ids => [])
    end

    def review_params
      params.require(:hit).permit(:message)  
    end

    def mturk_init
      @mturk = Mturk.new(sandbox: in_sandbox?)
    end

    def in_sandbox?
      if mturk_reviewable_hit_params[:sandbox].present?
        mturk_reviewable_hit_params[:sandbox] == 'true' ? true : false
      else
        true
      end
    end

    def get_hit_info(hit_id)
      task = Task.find_by(hit_id: hit_id)
      log = nil
      task_found = false
      if task.present?
        task_found = true
        log = task.results.first&.question_sequence_log&.log
      end
      return {task: task, log: log, task_found: task_found, hit_id: hit_id}
    end
  end
end
