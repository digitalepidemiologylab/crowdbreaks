require 'elasticsearch'
require 'faraday_middleware/aws_sigv4'
require 'stretchy'

module ElasticsearchApi
  extend ActiveSupport::Concern

  MAX_ASSIGNMENTS = 2
  MAX_VALIDATIONS = 5
  MAX_RETRIES = 5
  SLEEP_TIME = 5
  JSON_HEADER = { 'Content-Type' => 'application/json', :Accept => 'application/json' }.freeze
  DATE_FORMAT = '%Y-%m-%dT%T.000Z'.freeze

  service = 'es'

  @@es_client = Elasticsearch::Client.new(url: ENV['ES_HOST_PORT'], retry_on_status: [403], retry_on_failure: 5) do |f|
    f.request :aws_sigv4,
              service: service,
              region: Aws.config[:region],
              access_key_id: Aws.config[:credentials].access_key_id,
              secret_access_key: Aws.config[:credentials].secret_access_key
  end

  # @@es_client = Aws::ElasticsearchService::Client.new

  Stretchy.client = @@es_client

  def ping_es
    handle_es_errors(occured_when: 'pinging ES') do
      Helpers::ApiResponse.new(status: :success, body: @@es_client.ping)
    end
  end

  def es_stats
    handle_es_errors(occured_when: 'fetching ES stats') do
      Helpers::ApiResponse.new(status: :success, body: @@es_client.indices.stats)
    end
  end

  def es_health
    handle_es_errors(occured_when: 'fetching ES cluster health') do
      Helpers::ApiResponse.new(status: :success, body: @@es_client.cluster.health)
    end
  end

  def stream_activity(es_activity_threshold_min: 10)
    handle_es_errors(occured_when: 'counting ES activity') do
      query = { query: { range: { timestamp: { gte: "now-#{es_activity_threshold_min}m/m", lt: 'now/m' } } } }
      Helpers::ApiResponse.new(status: :success, body: @@es_client.count({ body: query }))
    end
  end

  def tweets(index:, user_id: nil, new_prob: 1.00)
    query_new = Stretchy.query.not.query(exists: { field: 'annotations' })
    query_not_finished = Stretchy.query.query(exists: { field: 'annotations' }).filter(
      'script': { 'script': "doc['annotations'].values.length < #{MAX_ASSIGNMENTS}" }
    ).filter(
      'bool': { 'must_not': [{ 'terms': { 'annotations': [user_id] } }] }
    )
    query_pipeline = lambda do |query, index|
      handle_es_errors(occured_when: 'fetching a new tweet from ES') do
        sample_predictions_query(recent_predictions_query(query), index: index).results
      end
    end
    tweets = rand > new_prob ? query_pipeline.call(query_not_finished, index) : query_pipeline.call(query_new, index)
    return tweets if tweets.is_a?(Hash)

    tweets = tweets.map { |tweet| Helpers::Tweet.new(id: tweet['_id'], text: tweet['text']) }.compact
    Helpers::ApiResponse.new(status: :success, body: tweets)
  end

  def update_tweet(index:, user_id:, tweet_id:)
    handle_es_errors(occured_when: 'updating a tweet on ES') do
      response = @@es_client.update(
        {
          id: tweet_id,
          type: '_doc',
          index: index,
          refresh: true,
          body: {
            script: {
              source: 'if (ctx._source.annotations == null) ctx._source.annotations = new ArrayList();' \
                      'ctx._source.annotations.add(params.annotation)',
              lang: 'painless',
              params: {
                annotation: { user_id: user_id }
              }
            }
          }
        }
      )
      Helpers::ApiResponse.new(status: :success, message: 'Successfully updated tweet.', body: response)
    end
  end

  def get_trending_tweets(
    index:, term: nil, start_date: 'now-1w', end_date: 'now',
    size: 10, min_doc_count: 10
  )
    # project_slug -> index
    # TODO: Example queries and Response, handle errors
    start_date = parse_dates(start_date)
    end_date = parse_dates(end_date)
    query = query.query(
      index: index,
      aggs: {
        trending_tweets_agg: { terms: { field: 'retweeted_status_id', size: size, min_doc_count: min_doc_count } }
      }
    ).fields('aggregations.trending_tweets_agg').range(created_at: { gte: start_date, lte: end_date })
    query = query.query(term: { text: term }) unless term.nil?
    handle_es_errors(occured_when: 'aggregating trending tweets on ES') do
      result = query.results[0]&.fetch('aggregations', nil)&.fetch('trending_tweets_agg', nil)&.fetch('buckets', [])
      Helpers::ApiResponse.new(status: :success, body: result)
    end
  end

  def get_trending_topics(slug:, **kwargs)
    # TODO: Implement
    # TODO: Example queries and Response, handle errors
    raise NotImplementedError
    # resp = self.class.get('/trending_topics/'+project_slug, body: kwargs.to_json, timeout: 10, headers: JSON_HEADER)
    # resp.parsed_response
  end

  # elasticsearch - all data, for monitoring stream activity
  def get_all_data(
    index:, keywords: nil, not_keywords: nil,
    start_date: 'now-20y', end_date: 'now', interval: 1.month, round_to_sec: nil
  )
    start_date = process_date(start_date, round_to_sec)
    end_date = process_date(end_date, round_to_sec)
    keywords = keywords.nil? ? [] : keywords
    not_keywords = not_keywords.nil? ? [] : not_keywords

    ranges = get_ranges(start_date, end_date, interval, format: DATE_FORMAT)
    definition = {
      aggs: { all_data_agg: { date_range: { field: 'created_at', format: 'strict_date_optional_time', ranges: ranges } } }
    }

    definition[:query] = {} unless keywords.empty? && not_keywords.empty?
    keywords.each do |keyword|
      if definition[:query]&.fetch(:bool, nil)&.fetch(:must, nil).nil?
        definition[:query][:bool] = { must: [{ match_phrase: { text: keyword } }] }
      else
        definition[:query][:bool][:must] << { match_phrase: { text: keyword } }
      end
    end
    not_keywords.each do |keyword|
      if definition[:query]&.fetch(:bool, nil)&.fetch(:must_not, nil).nil?
        definition[:query][:bool] = { must_not: [{ match_phrase: { text: keyword } }] }
      else
        definition[:query][:bool][:must_not] << { match_phrase: { text: keyword } }
      end
    end

    handle_es_errors(occured_when: 'aggregating tweets by keywords on ES') do
      result = @@es_client.search index: index, body: definition
      Helpers::ApiResponse.new(status: :success, body: result['aggregations']['all_data_agg']['buckets'])
    end
  end

  # elasticsearch - sentiment data
  def get_predictions(
    index:, question_tag:, answer_tags:, run_name: '',
    start_date: 'now-20y', end_date: 'now', interval: 'month', include_retweets: true
  )
    aggs = {
      prediction_agg: { date_histogram: { field: 'created_at', interval: interval, format: 'yyyy-MM-dd HH:mm:ss' } }
    }

    query = aggregation_query(aggs, index, question_tag, run_name, start_date, end_date, include_retweets)

    handle_es_errors(occured_when: 'aggregating predictions on ES') do
      predictions = {}
      answer_tags.each do |answer_tag|
        result = query.filter(term: { 'predictions.endpoints.label': answer_tag }).results[0]
        predictions[answer_tag] = result&.fetch('aggregations', nil)&.fetch('prediction_agg', nil)&.fetch('buckets', [])
      end
      Helpers::ApiResponse.new(status: :success, body: predictions)
    end
  end

  def get_avg_label_val(
    index:, question_tag:, run_name: '',
    start_date: 'now-20y', end_date: 'now', interval: 'month',
    include_retweets: true, with_moving_average: nil, moving_average_window_size: 10
  )
    aggs = {
      hist_agg: {
        date_histogram: { field: 'created_at', interval: interval, format: 'yyyy-MM-dd HH:mm:ss' },
        aggs: { mean_label_val: { avg: { field: 'predictions.endpoints.label_val' } } }
      }
    }
    unless with_moving_average
      aggs[:hist_agg][:aggs][:mean_label_val_moving_average] = {
        moving_avg: { buckets_path: 'mean_label_val', window: moving_average_window_size }
      }
    end
    query = aggregation_query(aggs, index, question_tag, run_name, start_date, end_date, include_retweets)
    handle_es_errors(occured_when: 'aggregating average label value on ES') do
      result = query.results[0]&.fetch('aggregations', nil)&.fetch('hist_agg', nil)&.fetch('buckets', [])
      Helpers::ApiResponse.new(status: :success, body: result)
    end
  end

  def get_geo_sentiment(**kwargs)
    raise NotImplementedError
    # Helpers::ErrorHandler.handle_error(error_return_value: []) do
    #   resp = self.class.get('/sentiment/geo', query: kwargs, timeout: 20)
    #   JSON.parse(resp)
    # end
  end

  # email status
  def get_streaming_email_status(type: 'weekly')
    raise NotImplementedError
    # kwargs = {type: type}
    # Helpers::ErrorHandler.handle_error(error_return_value: '') do
    #   resp = self.class.get('/email/status', query: kwargs, timeout: 20)
    #   resp.parsed_response
    # end
  end

  private

  def aggregation_query(aggs, index, question_tag, run_name, start_date, end_date, include_retweets)
    start_date = parse_dates(start_date)
    end_date = parse_dates(end_date)

    aggs_name = aggs.keys.map { |key| key.to_s if key.to_s.end_with?('_agg') }.compact[0]

    query = Stretchy.query(
      index: index, aggs: aggs
    ).fields("aggregations.#{aggs_name}").limit(1).range(
      created_at: { gte: start_date, lte: end_date }
    ).filter(
      term: { 'predictions.endpoints.question_tag': question_tag }
    )
    query = query.filter(term: { 'predictions.endpoints.run_name': run_name }) unless run_name.blank?
    query = query.not.query(exists: { field: 'is_retweet' }) unless include_retweets
    query
  end

  def get_ranges(start_date, end_date, interval)
    dates = []
    while end_date >= start_date
      dates.append end_date.utc.strftime(DATE_FORMAT)
      end_date -= Helpers::TimeParser.new(interval).time
    end
    dates = dates.reverse
    ranges = []
    dates.each_cons(2) do |start_date, end_date|
      ranges << { from: start_date, to: end_date }
    end
    ranges
  end

  def handle_es_errors(max_retries: MAX_RETRIES, occured_when: nil)
    retries = 0
    yield
  rescue Elasticsearch::Transport::Transport::Errors::Forbidden => e
    if retries < max_retires
      retries += 1
      Rails.logger.warning "Retrying #{retries}/#{max_retries}. #{e.class}: #{e.message}."
      sleep(sleep_time)
      retry
    else
      Helpers::ErrorHandler.error_log_response(occured_when, e)
    end
  rescue *[
    Elasticsearch::Transport::Transport::Errors::BadRequest,
    Elasticsearch::Transport::Transport::Errors::NotFound
  ] => e
    Helpers::ErrorHandler.error_log_response(occured_when, e)
  end

  def parse_dates(date)
    return date if date.include? 'now'

    Time.parse(date).utc.strftime(DATE_FORMAT)
  end

  def parse_date_datemath(date)
    return Helpers::TimeParser.new(date).datetime if date.include? 'now'

    Time.parse(date).utc
  end

  def process_date(date, round_to_sec)
    date = parse_date_datemath(date)
    return date if round_to_sec.nil?

    round_to_seconds(date, round_to_sec)
  end

  def recent_predictions_query(query, days_back: 14)
    query.range(
      created_at: { gte: (Time.now.utc - 60 * 60 * 24 * days_back).strftime(DATE_FORMAT) } # '%a %b %-d %T %z %Y' -- previous twitter strftime
    ).not.match(
      is_retweet: true
    ).not.match(
      has_quote: true
    ).query(
      { 'exists': { 'field': 'predictions' } }
    )
  end

  def round_to_seconds(time, seconds)
    remainder = seconds - (time.to_i % seconds)
    time + remainder
  end

  def sample_predictions_query(query, index:, limit: MAX_VALIDATIONS)
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
end
