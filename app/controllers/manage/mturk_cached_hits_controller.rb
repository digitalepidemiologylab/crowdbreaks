module Manage
  class MturkCachedHitsController < BaseController
    load_and_authorize_resource
    before_action :mturk_init

    def index
      @sandbox = param_is_truthy?(:sandbox, default: false)
      @platform_only = param_is_truthy?(:platform_only, default: true)
      @show_assignable = param_is_truthy?(:show_assignable, default: true)
      @show_unassignable = param_is_truthy?(:show_unassignable, default: true)
      @show_reviewable = param_is_truthy?(:show_reviewable, default: true)
      @show_reviewing = param_is_truthy?(:show_reviewing, default: true)
      statuses = []
      statuses.push('Assignable') if @show_assignable
      statuses.push('Unassignable') if @show_unassignable
      statuses.push('Reviewable') if @show_reviewable
      statuses.push('Reviewing') if @show_reviewing
      filters = {sandbox: @sandbox, hit_status: statuses}
      if @platform_only
        hit_types = MturkBatchJob.pluck(:hittype_id).reject{|v| v.blank?}
        filters[:hit_type_id] = hit_types
      end
      @mturk_cached_hits = MturkCachedHit.where(filters).all.order('creation_time DESC').page(params[:page]).per(50)
      @num_hits = MturkCachedHit.where(sandbox: @sandbox).count
      @balance = @mturk.check_balance.available_balance
      @last_updated = MturkCachedHit.where(sandbox: @sandbox).order('updated_at').last&.updated_at
      # filtered counts
      filters.delete(:hit_status)
      @num_assignable = MturkCachedHit.where(hit_status: 'Assignable', **filters).count
      @num_unassignable = MturkCachedHit.where(hit_status: 'Unassignable', **filters).count
      @num_reviewable = MturkCachedHit.where(hit_status: 'Reviewable', **filters).count
      @num_reviewing = MturkCachedHit.where(hit_status: 'Reviewing', **filters).count
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
