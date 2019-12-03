module Pipeline
  extend ActiveSupport::Concern
  PREFIX = 'pipeline'

  # pipeline
  def get_config
    handle_error(error_return_value: []) do
      resp = self.class.get("/#{PREFIX}/config")
      resp.parsed_response
    end
  end

  def status_all
    handle_error(error_return_value: []) do
      self.class.get("/#{PREFIX}/status/all")
    end
  end

  def status_streaming
    handle_error(error_return_value: 'error') do
      resp = self.class.get("/#{PREFIX}/status/stream")
      return resp.length > 20 ? 'error' : resp.strip
    end
  end

  def stream_activity(**options)
    options = {es_activity_threshold_min: options.fetch(:es_activity_threshold_min, 3000),
               redis_counts_threshold_hours: options.fetch(:redis_counts_threshold_hours, 2)}
    handle_error(error_return_value: {}) do
      resp = self.class.get("/#{PREFIX}/status/stream_activity", query: options)
      resp.parsed_response
    end
  end

  def set_config(data)
    handle_error_notification do
      self.class.post("/#{PREFIX}/config", body: data.to_json, headers: FlaskApi::JSON_HEADER)
    end
  end

  def stop_streaming
    handle_error_notification do
      self.class.get("/#{PREFIX}/stop", {timeout: 15})
    end
  end

  def start_streaming
    handle_error_notification do
      self.class.get("/#{PREFIX}/start")
    end
  end

  def restart_streaming
    handle_error_notification do
      self.class.get("/#{PREFIX}/restart")
    end
  end
end
