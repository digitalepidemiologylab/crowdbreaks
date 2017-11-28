require 'httparty'

class FlaskApi
  include HTTParty

  base_uri 'logstash-dev.crowdbreaks.org'

  def initialize
  end

  def self.ping
    begin
      resp = get("/", timeout: 5)
    rescue
      false
    else
      resp.success?
    end
  end
end
