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


  def add_answer(result)
    # only add stuff to ES if meta_field is provided for question
    unless result.question.meta_field.blank?
      # make sure meta field exists
      response = @client.perform_request('POST', "#{self.index_name}/#{self.document_type}/#{result.tweet_id}/_update", {},
                                         {
        "script": {
          "inline": "if (!ctx._source.containsKey(\"meta\")) { 
              ctx._source.meta = params.initial
            }",
          "params": {
            "initial": {
              "#{result.question.meta_field}": { }
            }
          }
        }
      })

      # increase counter for answer given
      answer = Answer.find_by(id: result.answer_id).key
      
      response = @client.perform_request('POST', "#{self.index_name}/#{self.document_type}/#{result.tweet_id}/_update", {},
        "script": {
          "inline": "
            if (ctx._source.meta.#{result.question.meta_field}.containsKey(\"#{answer}\")) { 
              ctx._source.meta.#{result.question.meta_field}.#{answer} += 1
            } else {
              ctx._source.meta.#{result.question.meta_field}.#{answer} = 1
            }"
          })
    end
  end
end
