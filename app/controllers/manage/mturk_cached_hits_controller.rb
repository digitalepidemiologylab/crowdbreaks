module Manage
  class MturkCachedHitsController < BaseController
    load_and_authorize_resource
    before_action :mturk_init

    def index
      @sandbox = param_is_truthy?(:sandbox, default: false)
      @filtered = param_is_truthy?(:filtered)
      @reviewable = param_is_truthy?(:reviewable)
      filters = {sandbox: @sandbox}
      if @filtered
        hit_types = MturkBatchJob.pluck(:hittype_id).reject{|v| v.blank?}
        filters['hit_type_id'] = hit_types
      end
      if @reviewable
        filters['hit_status'] = 'Reviewable'
      end
      @mturk_cached_hits = MturkCachedHit.where(filters).all.order('creation_time DESC').page(params[:page]).per(50)
      @num_hits = MturkCachedHit.where(sandbox: @sandbox).count
      @num_hits_reviewable = @num_hits - MturkCachedHit.where(sandbox: @sandbox, hit_review_status: 'NotReviewed').count
      @balance = @mturk.check_balance.available_balance
      @last_updated = MturkCachedHit.where(sandbox: @sandbox).order('updated_at').last&.updated_at
    end

    def show
    end

    def destroy
      return_val = @mturk.delete_hit(@mturk_cached_hit.hit_id, expire: true)
      if return_val.nil?
        if @mturk.get_hit(@mturk_cached_hit.hit_id).nil?
          redirect_to(mturk_cached_hits_path, alert: 'Destroying HIT failed. Hit does not exist anymore')
        else
          redirect_to(mturk_cached_hits_path, alert: 'Could not delte HIT. HITs can only be deleted in states of "Assignable", "Reviewing" or "Reviewable".')
        end
      else
        @mturk_cached_hit.destroy
        redirect_to(mturk_cached_hits_path, notice: 'Successfully deleted HIT.')
      end
    end

    def clear_all
      @sandbox = param_is_truthy?(:sandbox, default: false)
      # probably better to move this to a background job, but it should be relatively fast
      MturkCachedHit.where(sandbox: @sandbox).delete_all
      if MturkCachedHit.where(sandbox: @sandbox).count == 0
        redirect_to(mturk_cached_hits_path(sandbox: @sandbox), notice: 'Successfully cleared cached HITs')
      else
        redirect_to(mturk_cached_hits_path(sandbox: @sandbox), alert: 'Something went wrong when clearing cached HITs')
      end
    end

    def update_cached_hits
      if current_user
        UpdateMturkChachedHitsJob.perform_later(current_user.id, param_is_truthy?(:sandbox, default: false))
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
      @mturk = Mturk.new(sandbox: param_is_truthy?(:sandbox, default: false))
    end
  end
end
