module Manage
  class MlResourcesController < BaseController
    before_action :api_init
    authorize_resource class: false

    def list_ml_models
      authorize! :view, :ml
      @api_ready = @api.ping
    end

    private

    def api_init
      @api = FlaskApi.new
    end
  end
end
