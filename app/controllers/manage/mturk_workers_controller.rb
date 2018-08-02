module Manage
  class MturkWorkersController < BaseController
    def index
      @mturk_workers = MturkWorker.all.page params[:page]
    end
  end
end
