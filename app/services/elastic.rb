class Elastic
  attr_reader :index_name, :client, :document_type

  def initialize(index_name)
    @index_name = index_name
    @client = Crowdbreaks::Client
    @document_type = 'tweet'
  end

  def initial_tweet
    client.search(index: self.index_name,
                  body: {
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

  def validate_tweet_id(tweet_id)
    begin
      response = client.perform_request('HEAD', "#{self.index_name}/#{self.document_type}/#{tweet_id}")
    rescue
      return false
    else
      return true if response.status == 200
    end
    return false
  end


  def add_answer(tweet_id, question_id, answer_id)
    p tweet_id
    p question_id
    p answer_id
  end
end
