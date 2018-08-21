module Manage
  class MturkHitsController < BaseController
    authorize_resource class: false
    before_action :mturk_init

    def index
      @page = params[:page].present? ? params[:page].to_i : 1
      @sandbox = in_sandbox?
      hits_list = @mturk.list_hits(next_token: params[:next_token])
      @hits = hits_list[:hits]
      @next_token = hits_list[:next_token]
      @num_hits = hits_list[:num_results]
      @balance = @mturk.check_balance.available_balance
    end

    def show
      @hit = @mturk.get_hit(mturk_hit_params[:id])
    end

    def destroy
      return_val = @mturk.delete_hit(mturk_hit_params[:id])
      if return_val.nil?
        redirect_to(mturk_hits_path, alert: 'Could not delte HIT. HITs can only be deleted in states of "Reviewing" or "Reviewable".')
      else
        redirect_to(mturk_hits_path, notice: 'Successfully deleted HIT.')
      end
    end

    private

    def mturk_hit_params
      params.permit(:id, :sandbox)
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
