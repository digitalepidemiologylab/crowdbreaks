class AwsApi
  include MlApi
  include PipelineApi
  include ElasticsearchApi

  private

  def avoid_duplicate_requests(cache_key)
    return if Rails.cache.exist?(cache_key)

    Rails.cache.write(cache_key, 1, expires_in: 1.seconds)
    yield
  end

  def cached(cache_key, use_cache: false, cache_duration: 5.minutes)
    if use_cache
      if Rails.cache.exist?(cache_key)
        Rails.logger.info("Reading from cache key #{cache_key}")
        Rails.cache.read(cache_key)
      else
        response = yield
        unless response.error? || response.fail?
          Rails.logger.info("Setting cache key #{cache_key}")
          Rails.cache.write(cache_key, response, expires_in: cache_duration)
        end
        response
      end
    else
      # Invalidate previous cache
      Rails.cache.delete(cache_key)
      yield
    end
  end

  def method_args_from_parameters(method_binding:)
    method(
      caller_locations[0].label
    ).parameters.map(&:last).map { |var| [var, method_binding.local_variable_get(var)] }.to_h
  end
end
