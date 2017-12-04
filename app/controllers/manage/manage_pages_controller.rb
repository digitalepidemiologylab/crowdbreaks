require 'flask_api'

module Manage
  class ManagePagesController < BaseController
    def index
      @es_ready = Crowdbreaks::ESClient.ping
      api = FlaskApi.new
      @api_ready = api.ping
      @api_es_ready = api.test('es')
      @api_redis_ready = api.test('redis')
    end
  end
end
