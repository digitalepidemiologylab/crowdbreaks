module Manage
  class MturkCachedHitsController < BaseController
    load_and_authorize_resource
    before_action :mturk_init

    def index
      @sandbox = in_sandbox?
      @filtered = filtered?
      @mturk_cached_hits = MturkCachedHit.where(sandbox: @sandbox).all.order('creation_time DESC').page(params[:page]).per(50)
      @num_hits = MturkCachedHit.where(sandbox: @sandbox).count
      @num_hits_reviewable = @num_hits - MturkCachedHit.where(sandbox: @sandbox, hit_review_status: 'NotReviewed').count
      @balance = @mturk.check_balance.available_balance
      @last_updated = MturkCachedHit.where(sandbox: @sandbox).order('updated_at').last&.updated_at
      UpdateMturkChachedHitsJob.perform_later
    end

    def show
    end

    def destroy
      return_val = @mturk.delete_hit(mturk_hit_params[:id])
      if return_val.nil?
        redirect_to(mturk_hits_path, alert: 'Could not delte HIT. HITs can only be deleted in states of "Assignable", "Reviewing" or "Reviewable".')
      else
        redirect_to(mturk_hits_path, notice: 'Successfully deleted HIT.')
      end
    end

    def update_cached_hits
      if current_user
        # UpdateMturkChachedHitsJob.perform_later(current_user.id, in_sandbox?)
        UpdateMturkChachedHitsJob.perform_later
        respond_to do |format|
          format.js { head :ok }
        end
      else
        respond_to do |format|
          format.js { head :bad_request }
        end
      end
    end

    private

    def mturk_hit_params
      params.permit(:id, :sandbox, :filtered)
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

    def filtered?
      if params[:filtered].present?
        params[:filtered] == 'true' ? true : false
      else
        false
      end
    end
  end
end
