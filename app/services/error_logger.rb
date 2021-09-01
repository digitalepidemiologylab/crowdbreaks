class ErrorLogger
  def self.error(message)
    Rails.logger.error message
    Rollbar.error(message) if send_to_rollbar
  end

  def self.warn(message)
    Rails.logger.warn message
    Rollbar.warning(message) if send_to_rollbar
  end

  def self.send_to_rollbar
    ENV['ENVIRONMENT_NAME'] == 'production'
  end
end
