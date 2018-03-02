require 'httparty'

class FlaskApi
  include HTTParty

  default_timeout 5
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
    handle_error(error_return_value: []) do
      resp = self.class.get('/data/all/'+index, query: options, timeout: 20)
      JSON.parse(resp)
    end
  end

  def get_sentiment_data(value, options={})
    handle_error(error_return_value: []) do
      resp = self.class.get('/sentiment/data/'+value, query: options, timeout: 20)
      JSON.parse(resp)
    end
  end

  def get_vaccine_sentiment(text)
    data = {'text': text}
    handle_error do
      self.class.post('/sentiment/vaccine/', body: data.to_json, headers: JSON_HEADER)
    end
  end

  # pipeline
  def get_config
    handle_error(error_return_value: []) do
      resp = self.class.get('/pipeline/config')
      resp.parsed_response
    end
  end

  def status_all
    handle_error(error_return_value: []) do
      self.class.get('/pipeline/status/all')
    end
  end

  def status_streaming
    handle_error(error_return_value: 'error') do
      resp = self.class.get('/pipeline/status/logstash')
      return resp.length > 20 ? 'error' : resp.strip
    end
  end

  def set_config(data)
    handle_error_notification do
      self.class.post('/pipeline/config', body: data.to_json, headers: JSON_HEADER)
    end
  end

  def stop_streaming
    handle_error_notification do
      self.class.get('/pipeline/stop')
    end
  end

  def start_streaming
    handle_error_notification do
      self.class.get('/pipeline/start')
    end
  end

  def restart_streaming
    handle_error_notification do
      self.class.get('/pipeline/restart')
    end
  end

  # tweets
  def get_tweet(project, user_id: nil)
    data = {'user_id': user_id}
    tweet_id = nil
    handle_error do
      resp = self.class.get('/tweet/new/'+project, query: data, timeout: 2)
      tweet_id = resp.parsed_response
    end
    # If API is down, fetch a random tweet
    if tweet_id.nil? or not tweet_id.scan(/\D/).empty?
      puts 'API is down'
      tweet_id = Result.limit(1000).order('RANDOM()').first.tweet_id.to_s
    end
    tweet_id
  end

  def update_tweet(project, user_id, tweet_id)
    data = {'user_id': user_id, 'tweet_id': tweet_id}
    handle_error do
      self.class.post('/tweet/update/'+project, body: data.to_json, headers: JSON_HEADER)
    end
  end

  # elasticsearch
  def es_stats
    handle_error(error_return_value: {}) do
      resp = self.class.get('/elasticsearch/stats')
      resp.parsed_response['indices']
    end
  end

  def health
    handle_error(error_return_value: 'error') do
      resp = self.class.get('/elasticsearch/health')
      resp.parsed_response['status']
    end
  end

  def create_index(name)
    handle_error_notification do
      self.class.post('/elasticsearch/create', body: {name: name}.to_json, headers: JSON_HEADER)
    end
  end



  private

  def handle_error(error_return_value: nil)
    begin
      yield
    rescue
      error_return_value
    end
  end

  def handle_error_notification(message: 'An error occured')
    begin
      yield
    rescue
      Hashie::Mash.new({success: false, parsed_response: message, code: 400})
    end
  end
end
