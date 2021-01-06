module Manage
  class ManagePagesController < BaseController
    before_action :api_init

    def dashboard
      authorize! :view, :manage_dashboard
      @api_ready = @api.ping
      @status_all = @api.status_all
    end

    def streaming
      authorize! :configure, :streaming
      @stream_status = @api.status_streaming
      current_streams = @api.get_config
      current_streams ||= []
      @is_up_to_date = Project.is_up_to_date(current_streams)
      @projects = Project.primary
    end

    def monitor_streams
      authorize! :configure, :streaming
      config = @api.get_config
      if config.empty?
        @current_streams = []
        return
      end
      @current_streams = Project.primary.where(es_index_name: config.map{|stream| stream['es_index_name']})
      @stream_status = @api.status_streaming
    end

    def user_activity
      authorize! :view, :user_activity
      @interval = 'day'
    end

    private

    def api_init
      @api = FlaskApi.new
    end
  end
end
