class Tweet
  attr_accessor :message, :tweet_id

  def initialize(result)
    if result
      if result.key?(:_source)
        @message = result._source.message if result._source.message
        if result._source.key?(:source)
          source = result._source.source
          offset = source =~ /[\/]\d{18,}/
          @tweet_id = source[offset+1..-1] if offset
        end
      end
    end
  end
end
