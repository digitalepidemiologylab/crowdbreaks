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
      @models.each do |model|
        model['ActiveEndpoint'] = false
        return unless model['Tags'].present?
        if model['Tags']['project_name'].present?
          project_name = model['Tags']['project_name']
          model['ActiveEndpoint'] = Project.by_name(project_name).has_endpoint(model['ModelName'])
        end
      end
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
      project = Project.by_name(params[:project_name])
      if project.nil?
        redirect_to(list_models_ml_resources_path, error: "Could not activate endpoint. Project #{params[:project_name]} could not be found.")
      end
      project.add_endpoint(params[:model_name])
      if project.has_endpoint(params[:model_name])
        redirect_to(list_models_ml_resources_path, notice: 'Successfully activated endpoint. Restart stream for changes to be active.')
      else
        redirect_to(list_models_ml_resources_path, error: 'Something went wrong when trying to activate endpoint.')
      end
    end

    def deactivate_endpoint
      authorize! :view, :ml
      project = Project.by_name(params[:project_name])
      if project.nil?
        redirect_to(list_models_ml_resources_path, error: "Could not deactivate endpoint. Project #{params[:project_name]} could not be found.")
      end
      project.remove_endpoint(params[:model_name])
      if not project.has_endpoint(params[:model_name])
        redirect_to(list_models_ml_resources_path, notice: 'Successfully deactivated endpoint. Restart stream for changes to be active.')
      else
        redirect_to(list_models_ml_resources_path, error: 'Something went wrong when trying to deactivate endpoint.')
      end
    end


    private

    def api_init
      @api = FlaskApi.new
    end
  end
end
