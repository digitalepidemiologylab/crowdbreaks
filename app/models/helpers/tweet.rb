module Helpers
  class Tweet
    attr_reader :id, :text

    def initialize(id:, text:)
      raise(ArgumentError, 'text is not a string') unless text.is_a?(String) || text.nil?

      @id = Integer(id)
      @text = text
    end

    def to_h
      { tweet_id: @id, tweet_text: @text }
    end
  end
end
