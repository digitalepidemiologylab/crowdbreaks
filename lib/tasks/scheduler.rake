desc "This task is called by the Heroku scheduler add-on"
namespace :scheduler do
  task :watch_stream => :environment do
    if defined?(Rails) && (Rails.env == 'development')
      Rails.logger = Logger.new(STDOUT)
    end
    if ENV['ENVIRONMENT_NAME'] == 'production' and ENV['WATCH_STREAM'] == 'true'
      Rails.logger.info "Running watch stream task to check up on stream"
    else
      Rails.logger.debug "The watch stream task is only executed in production environments and with the env variable WATCH_STREAM set to 'true'" and next
    end
    cache_key = "watch_stream_error_report_sent"
    if Rails.cache.exist?(cache_key)
      Rails.logger.debug "Watch stream error report has already been sent. Exiting." and next
    end
    api = FlaskApi.new
    if not api.ping
      msg = 'Could not ping the stream application. It might not be running.'
      send_report(msg) and next
    end
    status = api.status_streaming
    if not status == 'running'
      msg = "The stream is currently in state '#{status}'"
      send_report(msg) and next
    end
    activity_options = {es_activity_threshold_min: 10, redis_counts_threshold_hours: 2}
    activity = api.stream_activity(activity_options)
    if activity.empty?
      msg = "The stream seems to be running but no activity measures could be retrieved."
      send_report(msg) and next
    end
    if activity['es_count'] == 0 or activity['redis_count'] == 0
      msg = "The stream seems to be running but with very low activity.\n
          Documents indexed on Elasticsearch: #{num(activity['es_count'])} (last #{activity_options[:es_activity_threshold_min]} min)
          Documents counted in Redis: #{num(activity['redis_count'])} (last #{activity_options[:redis_counts_threshold_hours]} hours)"
      send_report(msg) and next
    end
    es_health = api.es_health
    if es_health != 'green'
      msg = "Elasticsearch is currently in #{es_health} state."
      send_report(msg) and next
    end
  end
end

def num(larger_number)
  # format large number
  larger_number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
end

def send_report(msg)
  mailer = ApplicationMailer.new
  html_body = "<h1>Crowdbreaks Stream Error</h1><p>The following error was detected:</p><h3>#{msg}</h3>"
  options = {
    subject: 'Crowdbreaks Error report',
    from_name: 'Crowdbreaks',
    from_email: 'no-reply@crowdbreaks.org',
    email: ENV['WATCH_STREAM_WARNING_EMAIL'],
    html: html_body,
  }
  mailer.send_raw(options)
  cache_key = "watch_stream_error_report_sent"
  Rails.cache.write(cache_key, 1, expires_in: 12.hours)
end
