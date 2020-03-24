module Manage
  class MlResourcesController < BaseController
    before_action :api_init
    authorize_resource class: false

    def list_ml_models
      authorize! :view, :ml
      @api_ready = @api.ping
    end

    def ml_playground
      authorize! :view, :ml
    end

    def ml_predictions
      authorize! :view, :ml
    end

    private

    def api_init
      @api = FlaskApi.new
    end
  end
end
