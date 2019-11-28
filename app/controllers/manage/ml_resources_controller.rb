module Manage
  class MlResourcesController < BaseController
    before_action :api_init
    authorize_resource class: false

    def list_endpoints
      authorize! :view, :ml
      @api_ready = @api.ping
      @endpoints = @api.list_endpoints
    end

    def list_models
      authorize! :view, :ml
      @api_ready = @api.ping
      @models = @api.list_model_endpoints
    end

    private

    def api_init
      @api = FlaskApi.new
    end
  end
end
