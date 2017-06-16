class ElasticTweet
  attr_accessor :client
  include Elasticsearch::Client

  def self.search(index) 
    __elasticsearch__.search(
      {
        "query": {
          "match_all": {}
        },
        "_source": false,
        "size": 1,
        "sort": [
          {
            "created_at": {
              "order": "desc"
            }
          }
        ]
      }
    )
  end
end
