module Manage
  class MturkReviewableHitsController < BaseController
    authorize_resource class: false
    before_action :mturk_init

    def index
      @hit_type_id = mturk_reviewable_hit_params[:hit_type_id]
      @show_all = false
      @results_per_page = 30   # max 100
      if not @hit_type_id.present?
        @show_all = true
        hits_list = @mturk.list_reviewable_hits(next_token: params[:next_token], max_results: @results_per_page)
      else
        @mturk_batch_jobs = MturkBatchJob.where(hittype_id: @hit_type_id)
        hits_list = @mturk.list_reviewable_hits(hit_type_id: @hit_type_id, next_token: mturk_reviewable_hit_params[:next_token])
      end
      @hits = hits_list[:hits]
      @next_token = hits_list[:next_token]
      @num_hits = hits_list[:num_results]
      @page = mturk_reviewable_hit_params[:page].present? ? mturk_reviewable_hit_params[:page].to_i : 1
      @sandbox = in_sandbox?
    end

    def show
      @assignment_id = mturk_reviewable_hit_params[:id]
      @assignment_not_found = false
      @task_not_found = false
      assignment = @mturk.get_assignment(@assignment_id)
      if assignment.nil?
        Rails.logger.error "Could not find assignment for assignment Id #{@assignment_id}"
        @assignment_not_found = true
        return
      end
      @hit_id = assignment.hit.hit_id
      @task = Task.find_by(hit_id: @hit_id)
      if not @task.present?
        Rails.logger.error "Could not find task for HIT Id #{@hit_id}"
        @task_not_found = true
        return
      end

      @log = @task.results.first&.question_sequence_log&.log
      @default_accept_message = Mturk::DEFAULT_ACCEPT_MESSAGE
      @default_reject_message = Mturk::DEFAULT_REJECT_MESSAGE
    end

    def multi_review
      accepted = multi_review_params[:accepted]
      if accepted.nil? or accepted.empty?
        redirect_to(mturk_reviewable_hits_path, alert: "No HITs selected for accepting.") and return
      end
      accepted.each do |assignment_id|
        @mturk.approve_assignment(assignment_id)
      end
      redirect_to(mturk_reviewable_hits_path, notice: "Successfully accepted #{accepted.length} HIT(s).") and return
    end

    def accept
      @mturk.approve_assignment(review_params[:id], message: review_params[:message])
      redirect_to(mturk_reviewable_hits_path, notice: "Successfully accepted HIT.") and return
    end

    def reject
      @mturk.reject_assignment(review_params[:id], message: review_params[:message])
      redirect_to(mturk_reviewable_hits_path, notice: "Successfully rejected HIT.") and return
    end


    private

    def mturk_reviewable_hit_params
      params.permit(:id, :hit_type_id, :next_token, :page, :sandbox, :come_from, :locale)
    end

    def multi_review_params
      params.permit(:accepted => [])
    end

    def review_params
      params.require(:hit).permit(:id, :message)  
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
  end
end
