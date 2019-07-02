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
    handle_error(error_return_value: false) do
      resp = self.class.get("/", options)
      resp.success?
    end
  end

  def test_redis
    options = {timeout: 5}
    handle_error(error_return_value: false) do
      resp = self.class.get("/test/redis", options)
      resp.parsed_response == 'true'
    end
  end

  def test_es
    options = {timeout: 5}
    handle_error(error_return_value: false) do
      resp = self.class.get("/elasticsearch/test", options)
      resp.parsed_response == 'true'
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
      resp = self.class.get('/pipeline/status/stream')
      return resp.length > 20 ? 'error' : resp.strip
    end
  end

  def stream_activity(**options)
    options = {es_activity_threshold_min: options.fetch(:es_activity_threshold_min, 3000),
               redis_counts_threshold_hours: options.fetch(:redis_counts_threshold_hours, 2)}
    handle_error(error_return_value: {}) do
      resp = self.class.get('/pipeline/status/stream_activity', query: options)
      resp.parsed_response
    end
  end

  def set_config(data)
    handle_error_notification do
      self.class.post('/pipeline/config', body: data.to_json, headers: JSON_HEADER)
    end
  end

  def stop_streaming
    handle_error_notification do
      self.class.get('/pipeline/stop', {timeout: 15})
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
  def get_tweet(es_index_name, user_id: nil)
    data = {'user_id': user_id}
    tweet = nil
    handle_error do
      resp = self.class.get('/tweet/new/'+es_index_name, query: data, timeout: 2)
      tweet = resp.parsed_response.deep_symbolize_keys!
    end
    tweet
  end

  def remove_tweet(es_index_name, tweet_id)
    data = {'tweet_id': tweet_id}
    handle_error do
      self.class.post('/tweet/remove/'+es_index_name, body: data.to_json, headers: JSON_HEADER)
    end
  end

  def update_tweet(es_index_name, user_id, tweet_id)
    data = {'user_id': user_id, 'tweet_id': tweet_id}
    handle_error do
      self.class.post('/tweet/update/'+es_index_name, body: data.to_json, headers: JSON_HEADER)
    end
  end

  # elasticsearch - general
  def es_stats
    handle_error(error_return_value: {}) do
      resp = self.class.get('/elasticsearch/stats')
      resp.parsed_response['indices']
    end
  end

  def es_health
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

  # elasticsearch - all data
  def get_all_data(index, options={})
    handle_error(error_return_value: []) do
      resp = self.class.get('/data/all/'+index, query: options, timeout: 20)
      JSON.parse(resp)
    end
  end

  # elasticsearch - sentiment data
  def get_sentiment_data(value, options={})
    handle_error(error_return_value: []) do
      resp = self.class.get('/sentiment/data/'+value, query: options, timeout: 20)
      JSON.parse(resp)
    end
  end

  def get_avg_sentiment(options={})
    handle_error(error_return_value: []) do
      resp = self.class.get('/sentiment/average', query: options, timeout: 20)
      JSON.parse(resp)
    end
  end

  def get_vaccine_sentiment(text)
    data = {'text': text}
    handle_error do
      self.class.post('/sentiment/vaccine/', body: data.to_json, headers: JSON_HEADER)
    end
  end

  def get_geo_sentiment(options={})
    handle_error(error_return_value: []) do
      resp = self.class.get('/sentiment/geo', query: options, timeout: 20)
      JSON.parse(resp)
    end
  end

  # email status
  def get_streaming_email_status(type: 'weekly')
    options = {type: type}
    handle_error(error_return_value: '') do
      resp = self.class.get('/email/status', query: options, timeout: 20)
      resp.parsed_response
    end
  end

  private


  def handle_error(error_return_value: nil)
    begin
      yield
    rescue StandardError => e
      error_return_value
    end
  end

  def handle_error_notification(message: 'An error occured')
    begin
      yield
    rescue StandardError => e
      Hashie::Mash.new({success: false, parsed_response: message, code: 400})
    end
  end
end
