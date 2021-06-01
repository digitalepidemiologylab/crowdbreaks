module Helpers
  class ErrorHandler
    def self.handle_error(error_return_value: nil)
      yield
    rescue StandardError => e
      Rails.logger.error "An exception occurred. #{e.class}: #{e.message}. Traceback:\n#{e.backtrace.join("\n")}"
      error_return_value
    end
  end
end
