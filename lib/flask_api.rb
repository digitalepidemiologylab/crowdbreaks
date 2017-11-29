require 'httparty'

class FlaskApi
  include HTTParty

  base_uri ENV['FLASK_API_HOSTNAME']

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

  def get_vaccine_sentiment(text)
    # to test in console:
    # HTTParty.post(ENV['FLASK_API_HOSTNAME']+"/sentiment/vaccine", body: {"text": "This is a string"}.to_json, headers: { "Content-Type" => "application/json"  }, basic_auth: {username: ENV['FLASK_API_USERNAME'],password: ENV['FLASK_API_PASSWORD']})
    data = {'text': text}
    resp = self.class.post('/sentiment/vaccine', body: data.to_json, headers: {'Content-Type': 'application/json'}, basic_auth: @auth)
    resp
  end
end
