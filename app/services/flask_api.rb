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

  def test(service)
    options = {basic_auth: @auth, timeout: 5}
    begin
      resp = self.class.get("/test/"+service, options)
    rescue
      false
    else
      resp
    end
  end

  def get_all_data(options={})
    resp = self.class.get('/sentiment/data/all', query: options, basic_auth: @auth)
    JSON.parse(resp)
  end

  def get_sentiment_data(value, options={})
    resp = self.class.get('/sentiment/data/'+value, query: options, basic_auth: @auth)
    JSON.parse(resp)
  end

  def get_vaccine_sentiment(text)
    # to test in console:
    # HTTParty.post(ENV['FLASK_API_HOSTNAME']+"/sentiment/vaccine", body: {"text": "This is a string"}.to_json, headers: { "Content-Type" => "application/json"  }, basic_auth: {username: ENV['FLASK_API_USERNAME'],password: ENV['FLASK_API_PASSWORD']})
    data = {'text': text}
    self.class.post('/sentiment/vaccine', body: data.to_json, headers: {'Content-Type' => 'application/json'}, basic_auth: @auth)
  end

  # pipeline
  def get_config
    resp = self.class.get('/pipeline/config', basic_auth: @auth)
    resp.parsed_response
  end

  def status_streaming
    resp = self.class.get('/pipeline/status', basic_auth: @auth)
    return resp.length > 20 ? 'error' : resp.strip
  end

  def set_config(data)
    self.class.post('/pipeline/config', body: data.to_json, headers: {'Content-Type' => 'application/json', 'Accept': 'application/json'}, basic_auth: @auth)
  end

  def stop_streaming
    resp = self.class.get('/pipeline/stop', basic_auth: @auth)
  end

  def start_streaming
    resp = self.class.get('/pipeline/start', basic_auth: @auth)
  end

  def restart_streaming
    resp = self.class.get('/pipeline/restart', basic_auth: @auth)
  end
end