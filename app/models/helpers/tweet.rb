module Helpers
  class Tweet
    attr_reader :id, :text, :index

    def initialize(id:, text:, index:)
      raise(ArgumentError, 'text is not a string') unless text.is_a?(String) || text.nil?

      @id = String(id)
      @text = text
      @index = index
    end

    def to_h
      { tweet_id: @id, tweet_text: @text, tweet_index: @index }
    end

    def to_s
      "Tweet(id: #{@id}, text: #{@text}, index: #{index})"
    end
  end
end
