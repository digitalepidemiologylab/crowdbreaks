module Manage
  class ElasticsearchIndexesController < BaseController
    before_action :api_init
    authorize_resource class: false

    def new
    end

    def index
      stats = @api.es_stats
      @health = @api.health
      @indexes = []
      stats.each_pair do |k, v|
        unless k.starts_with?('.')
          @indexes << {'name': k, num_docs: v['total']['docs']['count'], size_bytes: v['total']['store']['size_in_bytes']} 
        end
      end
    end

    def create
      response = @api.create_index(elasticsearch_indexes_params[:name])
      respond_with_flash(response, elasticsearch_indexes_path)
    end

    private

    def api_init
      @api = FlaskApi.new
    end

    def elasticsearch_indexes_params
      params.require(:elasticsearch_index).permit(:name)
    end

    def respond_with_flash(response, redirect_path)
      if response.success?
        respond_to do |format|
          flash[:notice] = response.parsed_response
          format.html { redirect_to redirect_path }
        end
      else
        respond_to do |format|
          flash[:alert] = response.parsed_response
          format.html { redirect_to redirect_path }
        end
      end
    end
  end
end
