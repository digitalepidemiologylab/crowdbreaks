class TweetEmbedding
  include HTTParty

  def initialize(tweet_id)
    @options = { id: tweet_id,
                 hide_media: 'true',
                 conversation: 'none',
                 omit_script: 'true' }
    self.class.base_uri 'https://api.twitter.com'
  end

  def tweet_embedding
    self.class.get("/1.1/statuses/oembed.json", query: @options)['html']
  end
end
