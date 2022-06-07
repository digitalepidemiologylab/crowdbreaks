module Manage
  class MturkAutoBatchesController < BaseController
    before_action :set_mturk_auto_batch, only: :update

    def update
      @mturk_auto_batch.update_attributes(mturk_auto_batch_params)
      redirect_to(mturk_auto_path, notice: "MTurk batch '#{@mturk_auto_batch.mturk_batch_job.name}' has been evaluated.")
    end

    private

    def mturk_auto_batch_params
      params.require(:mturk_auto_batch).permit(:evaluated)
    end

    def set_mturk_auto_batch
      @mturk_auto_batch = MturkAutoBatch.find(params[:id])
    end
  end
end
