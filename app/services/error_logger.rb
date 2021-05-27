class ErrorLogger
  def self.error(msg)
    Rails.logger.error msg
    if send_to_rollbar
      Rollbar.error(msg)
    end
  end

  def self.warn(msg)
    Rails.logger.warn msg
    if send_to_rollbar
      Rollbar.warning(msg)
    end
  end

  private

  def self.send_to_rollbar
    ENV['ENVIRONMENT_NAME'] == 'production'
  end
end
