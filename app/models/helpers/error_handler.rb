module Helpers
  class ErrorHandler
    def self.handle_error(error, occured_when: nil)
      yield
    rescue error => e
      error_log_response(occured_when, e)
    end

    def self.error_log_response(occured_when, error)
      occured_when = " when #{occured_when}" unless occured_when.nil?
      log_message = "An exception occurred#{occured_when}. #{error.class}: #{error.message}\n" \
                    "Traceback:\n#{error.backtrace.join("\n")}"
      flash_message = "An exception occurred#{occured_when}. #{error.class}: #{error.message}" \
                      "#{error.message.end_with?('.') ? '' : '.'}"
      ErrorLogger.error(log_message)
      Helpers::ApiResponse.new(status: :error, message: flash_message)
    end
  end
end
