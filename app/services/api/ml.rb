module Ml
  extend ActiveSupport::Concern
  PREFIX = 'ml'

  def list_endpoints
    handle_error(error_return_value: []) do
      self.class.get("/#{PREFIX}/list_endpoints")
    end
  end

  def list_models
    handle_error(error_return_value: []) do
      self.class.get("/#{PREFIX}/list_models")
    end
  end

  def list_model_endpoints(use_cache: true)
    cache_key = "list_model_endpoints_response"
    cached(cache_key, use_cache=use_cache, cache_duration=10.minutes) do
      avoid_duplicate_requests(__method__.to_s) do
        handle_error(error_return_value: []) do
          resp = self.class.get("/#{PREFIX}/list_model_endpoints", timeout: 20)
          resp.parsed_response
        end
      end
    end
  end

  def create_endpoint(model_name)
    data = {'model_name': model_name}
    self.class.post("/#{PREFIX}/create_endpoint", body: data.to_json, headers: FlaskApi::JSON_HEADER)
  end

  def delete_endpoint(model_name)
    data = {'model_name': model_name}
    self.class.post("/#{PREFIX}/delete_endpoint", body: data.to_json, headers: FlaskApi::JSON_HEADER)
  end

  private

  def avoid_duplicate_requests(cache_key)
    return if Rails.cache.exist?(cache_key)
    Rails.cache.write(cache_key, 1, expires_in: 1.seconds)
    yield
  end
end
