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
    if use_cache
      if Rails.cache.exist?(cache_key)
        return Rails.cache.read(cache_key)
      end
    end
    resp = avoid_duplicate_requests(__method__.to_s) do
      _list_model_endpoints
    end
    return [] if resp.nil?
    Rails.cache.write(cache_key, resp.as_json, expires_in: 20.seconds)
    return resp
  end

  def _list_model_endpoints
    handle_error(error_return_value: []) do
      self.class.get("/#{PREFIX}/list_model_endpoints", timeout: 20)
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
