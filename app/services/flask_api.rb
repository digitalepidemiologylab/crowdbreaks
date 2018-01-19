require 'httparty'

class FlaskApi
  include HTTParty

  base_uri ENV['FLASK_API_HOSTNAME']
  # debug_output $stderr
  basic_auth ENV['FLASK_API_USERNAME'], ENV['FLASK_API_PASSWORD']
  JSON_HEADER = {'Content-Type' => 'application/json', :Accept => 'application/json'}

  def initialize
  end

  def ping
    options = {timeout: 5}
    begin
      resp = self.class.get("/", options)
    rescue
      false
    else
      resp.success?
    end
  end

  def test(service)
    options = {timeout: 5}
    begin
      resp = self.class.get("/test/"+service, options)
    rescue
      false
    else
      resp
    end
  end

  def get_all_data(index, options={})
    resp = self.class.get('/data/all/'+index, query: options)
    JSON.parse(resp)
  end

  def get_sentiment_data(value, options={})
    resp = self.class.get('/sentiment/data/'+value, query: options)
    JSON.parse(resp)
  end

  def get_vaccine_sentiment(text)
    data = {'text': text}
    self.class.post('/sentiment/vaccine', body: data.to_json, headers: JSON_HEADER)
  end

  # pipeline
  def get_config
    resp = self.class.get('/pipeline/config')
    resp.parsed_response
  end

  def status_all
    return self.class.get('/pipeline/status/all')
    # return resp.length > 20 ? 'error' : resp.strip
  end

  def status_streaming
    resp = self.class.get('/pipeline/status/logstash')
    return resp.length > 20 ? 'error' : resp.strip
  end

  def set_config(data)
    self.class.post('/pipeline/config', body: data.to_json, headers: JSON_HEADER)
  end

  def stop_streaming
    resp = self.class.get('/pipeline/stop')
  end

  def start_streaming
    self.class.get('/pipeline/start')
  end

  def restart_streaming
    self.class.get('/pipeline/restart')
  end

  # elasticsearch
  def es_stats
    resp = self.class.get('/elasticsearch/stats')
    resp.parsed_response['indices']
  end

  def create_index(name)
    self.class.post('/elasticsearch/create', body: {name: name}.to_json, headers: JSON_HEADER)
  end
end
