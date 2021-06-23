class WatchStream
  include Response
  CACHE_KEY = "watch_stream_error_report_sent"
  CACHE_KEY_EXPIRY = 1.hours

  def initialize
    @mailer = ApplicationMailer.new
    @api = AwsApi.new
    if defined?(Rails) && (Rails.env == 'development')
      Rails.logger = Logger.new(STDOUT)
    end

  end

  def check_all_systems
    if not check_api or not check_stream or not check_es
      false
    else
      true
    end
  end

  def check_es
    es_health = get_value_and_flash_now(@api.es_health)
    if es_health != 'green'
      msg = "Elasticsearch is currently in #{es_health} state."
      notify_and_deactivate(msg)
      return false
    end
    true
  end

  def check_stream
    status = @api.status_streaming
    if status.error?
      notify_and_deactivate(status.message)
      return false
    elsif status.body != :running
      notify_and_deactivate("The stream is currently in state '#{status}'")
      return false
    end

    response = @api.stream_activity(es_activity_threshold_min: 10)
    case response.status
    when :error
      notify_and_deactivate('There was an error trying to retrieve the ES activity.')
      return false
    when :success
      count = response.body['count']
      if count.zero?
        message = "The stream seems to be running but with very low activity.\n
               Documents indexed on Elasticsearch: #{num(count)} (last #{activity_options[:es_activity_threshold_min]} min)"
        notify_and_deactivate(message)
        return false
      end
    end
    true
  end

  def check_api
    if not @api.ping
      msg = 'Could not ping the stream application. It might not be running.'
      notify_and_deactivate(msg)
      return false
    end
    true
  end

  def should_run?
    # only run in production and if no error was found previously
    if not (ENV['ENVIRONMENT_NAME'] == 'production' and ENV['WATCH_STREAM'] == 'true')
      Rails.logger.debug "The watch stream task is only executed in production environments and with the env variable WATCH_STREAM set to 'true'"
      return false
    elsif Rails.cache.exist?(CACHE_KEY)
      Rails.logger.info "Watch stream error report has already been sent. Exiting."
      return false
    else
      Rails.logger.info "Running watch stream task to check up on stream"
      return true
    end
  end

  def notify_and_deactivate(msg)
    send_error_report(msg)
    deactivate
  end

  def activate
    if Rails.cache.exist?(CACHE_KEY)
      Rails.cache.delete(CACHE_KEY)
      Rails.logger.info "Successfully reactivated stream watch task."
      true
    else
      Rails.logger.error "Could not reactivate stream watch task."
      false
    end
  end

  def deactivate
    Rails.cache.write(CACHE_KEY, 1, expires_in: CACHE_KEY_EXPIRY)
  end

  def send_error_report(msg)
    html_body = "<h1>Crowdbreaks Stream Error</h1><p>The following error was detected:</p><h3>#{msg}</h3>"
    options = {
      subject: 'Crowdbreaks Error report',
      from_name: 'Crowdbreaks',
      from_email: 'no-reply@crowdbreaks.org',
      email: ENV['WATCH_STREAM_WARNING_EMAIL'],
      html: html_body,
    }
    @mailer.send_raw(options)
  end

  def num(larger_number)
    # format large number
    larger_number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
end
