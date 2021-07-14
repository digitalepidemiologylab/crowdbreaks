require 'elasticsearch'
require 'faraday_middleware/aws_sigv4'
require 'stretchy'
require 'json'

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

  def get_all_data(
    index:, keywords: nil, not_keywords: nil,
    start_date: 'now-20y', end_date: 'now', interval: 1.month, round_to_sec: nil, use_cache: true
  )
    # start_date = parse_dates(start_date)
    # end_date = parse_dates(end_date)
    start_date = process_date(start_date, round_to_sec)
    end_date = process_date(end_date, round_to_sec)
    keywords = keywords.nil? ? [] : keywords
    not_keywords = not_keywords.nil? ? [] : not_keywords

    ranges = get_ranges(start_date, end_date, interval)
    definition = {
      aggs: { all_data_agg: { date_range: { field: 'created_at', format: 'strict_date_optional_time', ranges: ranges } } }
    }

    # definition = {
    #   aggs: {
    #     all_data_agg: { date_histogram: { field: 'created_at', fixed_interval: interval, format: 'yyyy-MM-dd HH:mm:ss' } }
    #   },
    #   query: { bool: { filter: [{ range: { created_at: { gte: start_date, lte: end_date } } }] } }
    # }

    definition[:query] = {} unless keywords.empty? && not_keywords.empty?
    keywords.each do |keyword|
      if definition.dig(:query, :bool, :must).nil?
        definition[:query][:bool] = { must: [{ match_phrase: { text: keyword } }] }
      else
        definition[:query][:bool][:must] << { match_phrase: { text: keyword } }
      end
    end
    not_keywords.each do |keyword|
      if definition.dig(:query, :bool, :must_not).nil?
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

  def get_avg_label_val(
    index:, question_tag:, run_name:,
    start_date: 'now-20y', end_date: 'now', interval: 'month',
    include_retweets: true, with_moving_average: true, moving_average_window_size: 10, use_cache: true
  )
    aggs = {
      hist_agg: {
        date_histogram: { field: 'created_at', interval: interval, format: 'yyyy-MM-dd HH:mm:ss' },
        aggs: { mean_label_val: { avg: { field: "predictions.#{question_tag}.endpoints.#{run_name}.label_val" } } }
      }
    }
    if with_moving_average
      aggs[:hist_agg][:aggs][:mean_label_val_moving_average] = {
        moving_avg: { buckets_path: 'mean_label_val', window: moving_average_window_size }
      }
    end
    definition = aggregation_query(aggs, question_tag, run_name, start_date, end_date, include_retweets)

    cache_key = "get-avg-label-val-#{method_args_from_parameters(method_binding: binding).except(use_cache)}"
    cached(cache_key, use_cache: use_cache) do
      handle_es_errors(occured_when: 'aggregating average label value on ES') do
        result = @@es_client.search index: index, body: definition
        Helpers::ApiResponse.new(status: :success, body: result['aggregations']['hist_agg']['buckets'])
      end
    end
  end

  def get_geo_sentiment(**kwargs)
    raise NotImplementedError
  end

  def get_predictions(
    index:, question_tag:, answer_tags:, run_name:,
    start_date: 'now-20y', end_date: 'now', interval: 'month', include_retweets: true, use_cache: true
  )
    aggs = {
      prediction_agg: { date_histogram: { field: 'created_at', fixed_interval: interval, format: 'yyyy-MM-dd HH:mm:ss' } }
    }
    cache_key = "get-predictions-#{method_args_from_parameters(method_binding: binding).except(use_cache)}"
    cached(cache_key, use_cache: use_cache) do
      handle_es_errors(occured_when: 'aggregating predictions on ES') do
        predictions = {}
        answer_tags.each do |answer_tag|
          definition = aggregation_query(aggs, question_tag, run_name, start_date, end_date, include_retweets)
          definition[:query][:bool][:filter] << { term: { "predictions.#{question_tag}.endpoints.#{run_name}.label": answer_tag } }
          result = @@es_client.search index: index, body: definition
          predictions[answer_tag] = result['aggregations']['prediction_agg']['buckets']
        end
        Helpers::ApiResponse.new(status: :success, body: predictions)
      end
    end
  end

  def get_streaming_email_status(type: 'weekly')
    raise NotImplementedError
  end

  def get_trending_topics(slug:, **kwargs)
    raise NotImplementedError
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

  def stream_activity(es_activity_threshold_min: 10)
    handle_es_errors(occured_when: 'counting ES activity') do
      query = { query: { range: { timestamp: { gte: "now-#{es_activity_threshold_min}m/m", lt: 'now/m' } } } }
      Helpers::ApiResponse.new(status: :success, body: @@es_client.count({ body: query }))
    end
  end

  def tweets(index:, question_tag: 'sentiment', user_id: nil, new_prob: 0.0)
    Rails.logger.info "#{user_id} #{user_id.class}"
    query_new = { bool: { must_not: [{ exists: { field: 'annotations' } }] } }
    query_not_finished = { bool: {
      filter: [{ "script": {
        "script": "doc.containsKey('annotations.user_id') && doc['annotations.user_id'].size() > 0 && " \
                  "doc['annotations.user_id'].size() < #{MAX_ASSIGNMENTS}"
      } }],
      # [
      #   { exists: { field: 'annotations' } },
      #   { script: { script: {
      #     source: "doc['annotations'].value < params.max_assignments",
      #     lang: 'painless',
      #     params: {
      #       max_assignments: MAX_ASSIGNMENTS
      #     }
      #   } } }
      # ],
      # must: [
      #   { script: { script: "doc['annotations'].values.length < #{MAX_ASSIGNMENTS}" } }
      # ],
      must_not: [{ terms: { 'annotations.user_id': [user_id] } }]
    } }

    query_pipeline = lambda do |query, index|
      handle_es_errors(occured_when: 'fetching a new tweet from ES') do
        @@es_client.search(
          index: index, size: MAX_VALIDATIONS,
          body: sample_predictions_definition(recent_predictions_query(query), question_tag)
        )['hits']['hits']
      end
    end

    rand_num = rand
    tweets = rand_num > new_prob ? query_pipeline.call(query_not_finished, index) : query_pipeline.call(query_new, index)
    return tweets if tweets.is_a? Helpers::ApiResponse

    tweets = query_pipeline.call(query_new, index) if rand_num > new_prob && tweets.empty?

    tweets = tweets.map { |tweet| Helpers::Tweet.new(id: tweet['_id'], text: tweet['_source']['text'], index: tweet['_index']) }.compact
    Helpers::ApiResponse.new(status: :success, body: tweets)
  end

  def update_tweet(index:, user_id:, tweet_id:)
    handle_es_errors(occured_when: 'updating a tweet on ES') do
      response = @@es_client.update(
        { id: tweet_id, type: '_doc', index: index, refresh: true, body: {
          script: {
            source: 'if (ctx._source.annotations == null) ctx._source.annotations = new ArrayList();' \
                    'ctx._source.annotations.add(params.annotation)',
            lang: 'painless',
            params: { annotation: { user_id: user_id } }
          }
        } }
      )
      Helpers::ApiResponse.new(status: :success, message: 'Successfully updated tweet.', body: response)
    end
  end

  private

  def aggregation_query(aggs, question_tag, run_name, start_date, end_date, include_retweets)
    {
      aggs: aggs,
      query: { bool: {
        filter: [
          { range: { created_at: { gte: parse_dates(start_date), lte: parse_dates(end_date) } } },
          { exists: { field: "predictions.#{question_tag}.endpoints.#{run_name}" } }
        ],
        must_not: [include_retweets ? { exists: { field: 'is_retweet' } } : {}]
      } }
    }
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

  def handle_es_errors(occured_when: nil)
    retries = 0
    begin
      yield
    rescue *[
      Elasticsearch::Transport::Transport::Errors::Forbidden,
      Faraday::ConnectionFailed
    ] => e
      if retries < MAX_RETRIES
        retries += 1
        Rails.logger.info "Retrying #{retries}/#{MAX_RETRIES}. #{e.class}: #{e.message}."
        sleep(SLEEP_TIME)
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

  def recent_predictions_query(query, days_back: 7)
    { bool: {
      must: [
        { range: { created_at: { gte: (Time.now.utc - 60 * 60 * 24 * days_back).strftime(DATE_FORMAT) } } },
        { exists: { field: 'predictions' } }
      ],
      must_not: [
        { exists: { field: 'is_retweet' } },
        { exists: { field: 'has_quote' } }
      ]
    } }.deep_merge(query)
  end

  def round_to_seconds(time, seconds)
    Rails.logger.info "#{time}, #{seconds}"
    seconds = Integer(seconds)
    remainder = seconds - (Integer(time) % seconds)
    time + remainder
  end

  def sample_predictions_definition(query, question_tag)
    {
      query: { function_score: {
        script_score: { script: {
          source: "if (_score > params['_source']['predictions']['#{question_tag}']['endpoints']['primary_probability'])" \
                  ' { _score } else { 0 }'
        } },
        query: { function_score: { boost_mode: 'replace', functions: [{ random_score: {} }], query: query } }
      } }
    }
  end
end
