module Manage
  class MturkHitsController < BaseController
    def list_hits
      @page = params[:page].present? ? params[:page].to_i : 1
      @sandbox = true
      if params[:sandbox].present?
        @sandbox = params[:sandbox] == 'true' ? true : false
      end
      hits_list = Mturk.new(sandbox: @sandbox).list_hits(next_token: params[:next_token])
      @hits = hits_list[:hits]
      @next_token = hits_list[:next_token]
      @num_hits = hits_list[:num_results]
    end


    private

  end
end
