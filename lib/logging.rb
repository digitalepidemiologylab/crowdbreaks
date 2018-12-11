module Logging
  class LogFormatter < Logger::Formatter
    def call(severity, time, progname, msg)
      date_format = time.strftime("%Y-%m-%d %H:%M:%S")
      msg = "[#{date_format}] [#{severity}]: #{msg}\n"
      msg
    end
  end
end

