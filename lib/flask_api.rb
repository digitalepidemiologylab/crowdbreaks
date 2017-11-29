require 'httparty'

class FlaskApi
  include HTTParty

  base_uri 'logstash-dev.crowdbreaks.org'

  def initialize
    @auth = {username: ENV['FLASK_API_USERNAME'], password: ENV['FLASK_API_PASSWORD']}
  end

  def ping
    options = {basic_auth: @auth, timeout: 5}
    begin
      resp = self.class.get("/", options)
    rescue
      false
    else
      resp.success?
    end
  end
end
