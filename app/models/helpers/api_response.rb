module Helpers
  class ApiResponse
    attr_reader :status, :body, :message, :error_code

    def initialize(status:, body: nil, message: nil, error_code: nil)
      raise(ArgumentError, 'status should be in %i[success fail error]') unless %i[success fail error].include?(status)
      raise(ArgumentError, 'no message in an error response') if status == :error && message.nil?
      raise(ArgumentError, 'no message in a fail response') if status == :fail && message.nil?
      raise(ArgumentError, 'body in an error response') if status == :error && !body.nil?

      @status = status
      @body = body
      @message = message
    end

    def success?
      @status == :success
    end

    def error?
      @status == :error
    end

    def fail?
      @status == :fail
    end

    def to_s
      "ApiResponse(status: #{@status}, body: #{@body}, message: #{@message}, error_code: #{error_code})"
    end
  end
end
