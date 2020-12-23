module Manage
  class QualifiedWorkersController < BaseController
    load_and_authorize_resource :mturk_worker_qualification_list
    load_and_authorize_resource :qualified_worker, through: :mturk_worker_qualification_list

    def index
      @qualified_workers = @qualified_workers.page(params[:page]).per(10)
    end
  end
end
