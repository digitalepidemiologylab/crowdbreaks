module Helpers
  class TimeParser
    TOKENS = {
      's' => 1,
      'm' => 60,
      'h' => (60 * 60),
      'd' => (60 * 60 * 24)
    }.freeze

    attr_reader :time, :datetime

    def initialize(input)
      @input = input
      @time = 0
      @datetime = 0
      parse
    end

    def parse
      @input.scan(/(\d+)(\w)/).each do |amount, measure|
        @time += amount.to_i * TOKENS[measure]
      end
      @time unless @input.start_with?('now')

      case @input[3]
      when nil
        @datetime = Time.now.utc
      when '-'
        @datetime = Time.now.utc - @time
      when '+'
        @datetime = Time.now.utc + @time
      end
    end
  end
end
