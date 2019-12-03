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
      use_cache = params['use_cache'] == 'false' ? false : true
      @models = @api.list_model_endpoints(use_cache: use_cache)
    end

    def create_endpoint
      authorize! :view, :ml
      resp = @api.create_endpoint(params['model_name'])
      if resp
        redirect_to(list_models_ml_resources_path(use_cache: false), notice: 'Endpoint successfully created')
      else
        redirect_to(list_models_ml_resources_path(use_cache: false), error: 'Something went wrong when creating endpoint')
      end
    end

    def delete_endpoint
      authorize! :view, :ml
      resp = @api.delete_endpoint(params['model_name'])
      if resp
        redirect_to(list_models_ml_resources_path(use_cache: false), notice: 'Endpoint successfully deleted')
      else
        redirect_to(list_models_ml_resources_path(use_cache: false), error: 'Something went wrong when deleting endpoint')
      end
    end

    def activate_endpoint
      authorize! :view, :ml
      project = Project.where.not(es_index_name: nil).where(name: params[:project_name])&.first
      if project.nil?
        redirect_to(list_models_ml_resources_path, error: 'Could not activate endpoint')
      end
      redirect_to(list_models_ml_resources_path, notice: 'Successfully activated endpoint. Restart stream for changes to be active.')

    end

    private

    def api_init
      @api = FlaskApi.new
    end
  end
end
