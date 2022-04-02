module Manage
  class MturkAutoController < BaseController
    include Response
    include MturkAutoHelper

    before_action :api_init
    class_attribute :new_batch_each, default: '2'

    RULE_NAME = 'crowdbreaks-auto-mturking-new-batch-cron'.freeze

    def index
      @new_batch_each = MturkAutoController.new_batch_each
    end

    def update
      if Time.now.day > 15
        respond_with_flash(
          Helpers::ApiResponse.new(
            status: :error,
            message: 'Cannot update the rule from the website after the 15th of each month. ' \
                    'To update the rule, write to olesia.altunina@epfl.ch'
          ),
          mturk_auto_path
        )
      else
        new_batch_each = mturk_auto_params[:new_batch_each]
        new_batch_cron =
          if new_batch_each.number?
            "0 0 1 */#{new_batch_each} ? *"
          else
            # new_batch_each
            respond_with_flash(
              Helpers::ApiResponse.new(
                status: :error, message: 'Cannot update the cron rule. Please enter a number of months.'
              ),
              mturk_auto_path
            )
          end
        response = @api.create_update_cron_event(name: RULE_NAME, cron: new_batch_cron)
        respond_with_flash(response, mturk_auto_path)
        MturkAutoController.new_batch_each = new_batch_each if response.status == :success
      end
    end

    private

    def mturk_auto_params
      params.require(:mturk_auto).permit(:new_batch_each)
    end

    def api_init
      @api = AwsApi.new
    end
  end
end
