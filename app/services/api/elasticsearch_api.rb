module ElasticsearchApi
  extend ActiveSupport::Concern

  service = 'es'

  client = Elasticsearch::Client.new(url: ENV['ES_HOST_PORT']) do |f|
    f.request :aws_sigv4,
              service: service,
              region: Aws.config[:region],
              access_key_id: Aws.config[:credentials].access_key_id,
              secret_access_key: Aws.config[:credentials].secret_access_key
  end

  # client = Aws::ElasticsearchService::Client.new

  Stretchy.client = client

  def ping
    client.ping
  end

  def es_stats
    handle_error(error_return_value: {}) do
      client.indices.stats['indices']
    end
  end

  def es_health
    handle_error(error_return_value: 'error') do
      client.cluster.health
    end
  end

  def create_index(params)
    # Not needed if the indices are created automatically
    handle_error_notification do
      name = params.delete('name')
      client.indices.create(index: name, body: params.to_json, headers: FlaskApi::JSON_HEADER)
    end
  end

  def update_tweet(index:, user_id:, tweet_id:)
    handle_error do
      client.update(
        {
          id: tweet_id,
          type: '_doc',
          index: index,
          refresh: true,
          body: {
            script: {
              source: 'ctx._source.annotations.add(params.annotation)',
              lang: 'painless',
              params: {
                annotation: { user_id: user_id }
              }
            }
          }
        }
      )
    end
  end

  def get_trending_tweets(
    index:, term: nil, start_date: 'now-1w', end_date: 'now',
    size: 10, min_doc_count: 10
  )
    # project_slug -> index
    # TODO: Example queries and responses, handle errors
    start_date = parse_dates(start_date)
    end_date = parse_dates(end_date)

    query = if term.nil?
              Stretchy.query()
            else
              Stretchy.query(term: { text: term })
            end

    query = query.query(
      index: index,
      aggs: {
        trending_tweets: {
          terms: {
            field: 'retweeted_status_id',
            size: size,
            min_doc_count: min_doc_count
          }
        }
      }
    ).fields('aggregations.trending_tweets').range(
      created_at: { gte: start_date, lte: end_date }
    )

    result = query.results[0]
    result&.fetch(
      'aggregations', nil
    )&.fetch(
      'trending_tweets', nil
    )&.fetch(
      'buckets', []
    )
  end

  def get_trending_topics(slug:, **kwargs)
    # TODO: Implement
    # TODO: Example queries and responses, handle errors
    raise NotImplementedError
    # resp = self.class.get('/trending_topics/'+project_slug, body: kwargs.to_json, timeout: 10, headers: JSON_HEADER)
    # resp.parsed_response
  end

  # elasticsearch - all data
  def get_all_data(
    index:, keywords: nil, not_keywords: nil,
    start_date: 'now-20y', end_date: 'now'
  )
    # TODO: Example queries and responses, handle errors
    start_date = parse_dates(start_date)
    end_date = parse_dates(end_date)
    keywords = keywords.nil? ? [] : keywords
    not_keywords = not_keywords.nil? ? [] : not_keywords

    query = Stretchy.query(
      index: index,
      aggs: {
        sentiment: {
          date_histogram: {
            field: 'created_at',
            interval: kwargs.fetch('interval', 'month'),
            format: 'yyyy-MM-dd HH:mm:ss'
          }
        }
      }
    ).limit(0).range(
      created_at: { gte: start_date, lte: end_date }
    )
    keywords.each do |keyword|
      query = query.query(match_phrase: { text: keyword })
    end
    not_keywords.each do |keyword|
      query = query.not.query(match_phrase: { text: keyword })
    end

    result = query.results[0]
    result&.fetch('aggregations', nil)&.fetch('sentiment', nil)&.fetch('buckets', [])
  end

  # elasticsearch - sentiment data
  def get_predictions(
    index:, question_tag:, answer_tags:, run_name: '',
    start_date: 'now-20y', end_date: 'now',
    include_retweets: true, use_cache: true
  )
    # use_cache -- deprecated
    start_date = parse_dates(start_date)
    end_date = parse_dates(end_date)

    query = Stretchy.query(
      index: index,
      aggs: {
        prediction_agg: {
          date_histogram: {
            field: 'created_at',
            interval: kwargs.fetch('interval', 'month'),
            format: 'yyyy-MM-dd HH:mm:ss'
          }
        }
      }
    ).fields('aggregations.prediction_agg').limit(0).range(
      created_at: { gte: start_date, lte: end_date }
    ).filter(
      term: { 'predictions.endpoints.question_tag': question_tag }
    )

    unless run_name.blank?
      query = query.filter(
        term: { 'predictions.endpoints.run_name': run_name }
      )
    end

    unless include_retweets
      query = query.not.query(exists: { field: 'is_retweet' })
    end

    predictions = {}
    answer_tags.each do |answer_tag|
      result = query.filter(
        term: { 'predictions.endpoints.label': answer_tag }
      ).results[0]
      predictions[answer_tag] = result&.fetch(
        'aggregations', nil
      )&.fetch(
        'prediction_agg', nil
      )&.fetch(
        'buckets', []
      )
    end

    predictions
  end

  def get_avg_label_val(
    index:, question_tag:, run_name: '',
    start_date: 'now-20y', end_date: 'now',
    with_moving_average: nil, moving_average_window_size: 10,
    interval: 'month', include_retweets: true, use_cache: true
  )
    start_date = parse_dates(start_date)
    end_date = parse_dates(end_date)

    aggs = {
      hist_agg: {
        date_histogram: {
          field: 'created_at',
          interval: interval,
          format: 'yyyy-MM-dd HH:mm:ss'
        },
        aggs: {
          mean_label_val: {
            avg: {
              field: 'predictions.endpoints.label_val'
            }
          }
        }
      }
    }

    unless with_moving_average
      aggs[:hist_agg][:aggs][:mean_label_val_moving_average] = {
        moving_avg: {
          buckets_path: 'mean_label_val',
          window: moving_average_window_size
        }
      }
    end

    query = Stretchy.query(
      index: index, aggs: aggs
    ).fields(
      'aggregations.hist_agg'
    ).limit(0).range(
      created_at: { gte: start_date, lte: end_date }
    ).filter(
      term: { 'predictions.endpoints.question_tag': question_tag }
    )

    unless run_name.nil?
      query = query.filter(
        term: { 'predictions.endpoints.run_name': run_name }
      )
    end

    unless include_retweets
      query = query.not.query(exists: { field: 'is_retweet' })
    end

    result = query.results[0]
    result&.fetch(
      'aggregations', nil
    )&.fetch(
      'hist_agg', nil
    )&.fetch(
      'buckets', []
    )
  end

  def get_geo_sentiment(**kwargs)
    raise NotImplementedError
    # handle_error(error_return_value: []) do
    #   resp = self.class.get('/sentiment/geo', query: kwargs, timeout: 20)
    #   JSON.parse(resp)
    # end
  end

  # email status
  def get_streaming_email_status(type: 'weekly')
    raise NotImplementedError
    # kwargs = {type: type}
    # handle_error(error_return_value: '') do
    #   resp = self.class.get('/email/status', query: kwargs, timeout: 20)
    #   resp.parsed_response
    # end
  end

  def tweet(index:, user_id: nil, new_prob: 1.00)
    # TODO: Example queries and responses, handle errors
    query_new = Stretchy.query.not.query(exists: { field: 'annotations' })
    query_not_finished = Stretchy.query.query(
      exists: { field: 'annotations' }
    ).not.query(
      exists: { field: 'annotations_finished' }
    )

    query_pipeline = lambda do |query, index|
      send_query(sample_predictions_query(recent_predictions_query(query), index: index))
    end

    if rand > new_prob
      tweet = query_pipeline.call(query_not_finished, index)[0]
    else
      tweet = nil # Need to define tweet outside the loop to then be returned outside the loop
      try_again = true
      while try_again
        try_again = false
        tweet = query_pipeline.call(query_new, index)[0]
        return tweet if tweet == false # If there's an error, return false

        tweet.fetch('annotations', []).each do |annotation|
          try_again = true if annotation['user_id'].to_s == user_id.to_s
        end
      end
    end
    Services::Tweet.new(id: tweet['_id'], text: tweet['text'])
  end

  private

  def parse_dates(*dates)
    parsed_dates = []
    dates.each do |date|
      if date.include? 'now'
        parsed_dates.append(date)
      else
        parsed_dates.append(Time.parse(date).utc.strftime('%Y-%m-%dT%T.000Z'))
      end
    end
    parsed_dates
  end

  def recent_predictions_query(query, days_back: 14)
    query.range(
      created_at: { gte: (Time.now.utc - 60 * 60 * 24 * days_back).strftime('%Y-%m-%dT%T.000Z') } # '%a %b %-d %T %z %Y' -- previous twitter strftime
    ).not.match(
      is_retweet: true
    ).not.match(
      has_quote: true
    ).query(
      { 'exists': { 'field': 'predictions' } }
    )
  end

  def sample_predictions_query(query, index:, limit: 1)
    nested_query = {
      function_score: {
        script_score: {
          script: {
            source: "if (_score > params['_source']['predictions']['primary']) { _score } else { 0 }"
          }
        },
        query: query.boost(boost_mode: 'replace').random({}).request[:body][:query]
      }
    }
    Stretchy.query(index: index).query(nested_query).limit(limit).offset(0).fields(:text, :annotations)
  end

  def send_query(query, retries: 5, sleep_time: 5)
    return false if retries.zero?

    query.results
  rescue *[
    Elasticsearch::Transport::Transport::Errors::BadRequest,
    Elasticsearch::Transport::Transport::Errors::NotFound
  ] => e
    Rails.logger.info "Trial #{trials}. #{e.class}: #{e.message}."
    false
  rescue Elasticsearch::Transport::Transport::Errors::Forbidden
    sleep(sleep_time)
    send_query(query, retries: retries - 1)
  end
end
