module Logging
  class LogFormatter < Logger::Formatter
    def call(severity, time, progname, msg)
      date_format = time.strftime("%Y-%m-%d %H:%M:%S")
      "[#{date_format}] [#{severity}]: #{msg}\n"
    end
  end
end

