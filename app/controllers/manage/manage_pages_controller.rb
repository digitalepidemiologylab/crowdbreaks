module Manage
  class ManagePagesController < BaseController
    def dashboard
      @es_ready = Crowdbreaks::ESClient.ping
      api = FlaskApi.new
      @api_ready = api.ping
      @api_es_ready = api.test('es')
      @api_redis_ready = api.test('redis')
      @stream_status = api.status_streaming
    end


    def streaming
      api = FlaskApi.new
      @current_streams = api.get_config
      @stream_status = api.status_streaming
      @projects = Project.all
    end

    def stop_streaming
    end

  end
end
