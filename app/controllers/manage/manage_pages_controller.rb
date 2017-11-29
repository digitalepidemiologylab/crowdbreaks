require 'flask_api'

module Manage
  class ManagePagesController < BaseController
    def index
      @es_ready = Crowdbreaks::ESClient.ping
      api = FlaskApi.new
      @api_ready = api.ping
    end
  end
end
