module Manage
  class ManagePagesController < BaseController
    before_action :api_init

    def dashboard
      @es_ready = Crowdbreaks::ESClient.ping
      @api_ready = @api.ping
      @status_all = @api.status_all
    end


    def streaming
      @stream_status = @api.status_streaming
      @current_streams = @api.get_config
      @is_up_to_date = Project.is_up_to_date(@current_streams)
      @projects = Project.all
    end

    def current_streams
      @current_streams = @api.get_config
    end

    def monitor_streams
      config = @api.get_config
      @current_streams = Project.select(:title_translations, :es_index_name).where(slug: config.keys)
    end

    def sentiment_analysis_chart
      @interval = 'hour'
      @project = Project.find_by('es_index_name': 'project_vaccine_sentiment')
    end

    private 

    def api_init
      @api = FlaskApi.new
    end
  end
end
