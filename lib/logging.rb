module Logging
  class LogFormatter < Logger::Formatter
    def call(severity, time, progname, msg)
      date_format = time.strftime("%Y-%m-%d %H:%M:%S")
      msg = "[#{date_format}] [#{severity}]: #{msg}\n"
      if severity == 'ERROR'
        Rollbar.error(msg)
      elsif severity == 'WARNING'
        Rollbar.warning(msg)
      end
      msg
    end
  end
end

