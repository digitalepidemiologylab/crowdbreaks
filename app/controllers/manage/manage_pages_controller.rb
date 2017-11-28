require 'flask_api'

module Manage
  class ManagePagesController < BaseController
    def index
      @es_ready = Crowdbreaks::ESClient.ping
      @api_ready = FlaskApi.ping
    end
  end
end
