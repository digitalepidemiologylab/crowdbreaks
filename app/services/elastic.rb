class Elastic
  attr_reader :index_name, :client, :document_type

  # Number of times a tweet should be answered (by unique users)
  MAX_ANSWERS = 5 
  # Probability of picking a new tweet (exploration parameter)
  P_NEW_TWEET = 0.2
  # Calculate relevance score only after n answers were given
  CALC_REL_THRESHOLD = 3

  def initialize(index_name)
    @index_name = index_name
    @client = Crowdbreaks::Client
    @document_type = 'tweet'
  end

  def initial_tweet(user_id)
    # decide if new tweet or previously answered
    response = nil
    if Random.rand < P_NEW_TWEET
      response = pick_new_tweet
    else
      # exclude tweets previously answered by user
      exclude_ids = Result.where(user_id: user_id).pluck(:tweet_id).uniq
      exclude_ids.delete(nil)
      response = pick_old_tweet(exclude_ids)
    end
    return extract_id_from_response(response)
  end

  def pick_new_tweet
    puts "NEW TWEET"
    # find most recent non answered tweet
    client.search(index: self.index_name, body: {
      "query": {
        "bool": {
          "must_not": {
            "exists": {
              "field": "meta.answer_count"
            }
          }
        }
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
    })
  end

  def pick_old_tweet(exclude_ids)
    puts "OLD TWEET"
    # pick one of the already answered tweets, which user has not answered before
    response = client.search(index: self.index_name, body: {
      "query": {
        "bool": {
          "must": {
            "range": {
              "meta.answer_count": {
                "lte": MAX_ANSWERS
              }
            }
          },
          "must_not": {
            "terms": {
              "_id": exclude_ids
            }
          }
        }
      },
      "_source": false,
      "size": 1,
      "sort": [
        {
          "meta.answer_count": {
            "order": "asc"
          }
        },
        {
          "meta.relevance_score": {
            "order": "desc"
          }
        }
      ]
    })
    # pick new tweet if serach conditions are not met, otherwise return tweet id 
    if response['hits']['total'] == 0
      puts "COULD NOT FIND OLD TWEET"
      pick_new_tweet
    else
      response
    end
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
      results_for_tweet = Result.where(tweet_id: result.tweet_id)
      num_results_for_tweet = results_for_tweet.count
      num_same_answer = results_for_tweet.where(question_id: result.question_id, answer_id: result.answer_id).count

      answer = Answer.find_by(id: result.answer_id).key
      client.update(index: self.index_name, type: self.document_type, id: result.tweet_id, body: { 
        doc: {
          meta: {
            "#{result.question.meta_field}": {
              "#{answer}": "#{num_same_answer}".to_i
            }
          }
        }
      })

      # update answer count
      self.update_answer_count(result.tweet_id, num_results_for_tweet)

      # update relevance score
      self.update_relevance_score(result.tweet_id, result.question.meta_field) if result.question.use_for_relevance_score
    end
  end

  def update_relevance_score(tweet_id, meta_field)
    response = client.perform_request('GET', "#{self.index_name}/#{self.document_type}/#{tweet_id}")
    relevance = response.body['_source']['meta']["#{meta_field}"]
    num_yes = relevance['yes'] ? relevance['yes'] : 0
    num_no = relevance['no'] ? relevance['no'] : 0
    return if ((num_yes == 0 and num_no == 0) or num_yes+num_no < CALC_REL_THRESHOLD)
    relevance_score = num_yes/(num_yes + num_no)

    client.update(index: self.index_name, type: self.document_type, id: tweet_id, body: { 
      doc: {
        meta: {
          relevance_score: relevance_score
        }
      }
    })
  end

  def update_answer_count(tweet_id, num_answers)
    client.update(index: self.index_name, type: self.document_type, id: tweet_id, body: { 
      doc: {
        meta: {
          answer_count: num_answers
        }
      }
    })
  end

  def extract_id_from_response(response)
    raise 'No response. Something went wrong. Please come back later.' if response.nil?
    if response['hits']['total'] > 0
      response['hits']['hits'].first['_id']
    else
      nil
    end
  end
end
