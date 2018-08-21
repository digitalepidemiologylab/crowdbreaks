module Manage
  class MturkReviewableHitsController < BaseController
    authorize_resource class: false
    before_action :mturk_init

    def index
      @sandbox = in_sandbox?
      @mturk_batch_jobs = MturkBatchJob.all.where(sandbox: @sandbox).order('created_at DESC').page(params[:page]).per(10)
    end


    def show
      hit_type_id = mturk_reviewable_hit_params[:id]
      @mturk_batch_jobs = MturkBatchJob.where(hittype_id: hit_type_id)
      hits_list = @mturk.list_reviewable_hits(hit_type_id: hit_type_id, next_token: params[:next_token])
      @hits = hits_list[:hits]
      @next_token = hits_list[:next_token]
      @num_hits = hits_list[:num_results]
      @page = params[:page].present? ? params[:page].to_i : 1
    end


    def multi_review
      accepted = multi_review_params[:accepted]
      if accepted.nil? or accepted.empty?
        redirect_to(mturk_reviewable_hit_path(params[:mturk_reviewable_hit_id]), alert: "No HITs selected for accepting.") and return
      end

      accepted.each do |assignment_id|
        @mturk.approve_assignment(assignment_id)
      end

      redirect_to(mturk_reviewable_hit_path(params[:mturk_reviewable_hit_id]), notice: "Successfully accepted #{accepted.length} HIT(s).") and return
    end

    private

    def mturk_reviewable_hit_params
      params.permit(:id, :sandbox)
    end

    def multi_review_params
      params.permit(:id, :accepted => [])
    end

    def mturk_init
      @mturk = Mturk.new(sandbox: in_sandbox?)
    end

    def in_sandbox?
      if params[:sandbox].present?
        params[:sandbox] == 'true' ? true : false
      else
        true
      end
    end
  end
end
