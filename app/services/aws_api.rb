require 'elasticsearch'
require 'faraday_middleware/aws_sigv4'
require 'stretchy'

class AwsApi
  include Ml
  include Pipeline
  include ElasticsearchApi

  private

  def cached(cache_key, use_cache=false, cache_duration=5.minutes)
    if use_cache
      if Rails.cache.exist?(cache_key)
        Rails.logger.info("Reading from cache key #{cache_key}")
        return Rails.cache.read(cache_key)
      else
        resp = yield
        has_error = false
        if resp.is_a? Hash
          if resp.key?('success')
            has_error = !resp['success']
          end
        end
        unless resp.nil? or resp == [] or resp == {} or has_error
          Rails.logger.info("Setting cache key #{cache_key}")
          Rails.cache.write(cache_key, resp, expires_in: cache_duration)
        end
        return resp
      end
    else
      # invalidate previous cache
      Rails.cache.delete(cache_key)
      return yield
    end
  end

  def handle_error(error_return_value: nil)
    yield
  rescue StandardError
    Rails.logger.error "An exception occurred. #{e.class}: #{e.message}. Traceback:\n#{e.backtrace.join("\n")}"
    error_return_value
  end

  def handle_error_notification(message = 'An error occured')
    yield
  rescue StandardError
    Rails.logger.error "An exception occurred. #{e.class}: #{e.message}. Traceback:\n#{e.backtrace.join("\n")}"
    Hashie::Mash.new({ success: false, parsed_response: message, code: 400 })
  end
end
