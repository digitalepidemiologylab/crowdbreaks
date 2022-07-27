# frozen_string_literal: true

require 'timeout'
require 'elasticsearch'
require 'faraday_middleware/aws_sigv4'
require 'stretchy'
require 'json'

##
# Elasticsearch (ES) API for the Project s with +storage_mode+ in <tt>[s3-es, s3-es-no-retweets]</tt>.
# Uses {Elasticsearch Ruby client}[https://github.com/elastic/elasticsearch-ruby] to send requests to ES.
module ElasticsearchApi
  extend ActiveSupport::Concern

  MAX_RETRIES = 5
  SLEEP_TIME = 5
  TIMEOUT = 40
  JSON_HEADER = { 'Content-Type' => 'application/json', :Accept => 'application/json' }.freeze
  DATE_FORMAT = '%Y-%m-%dT%T.000Z'

  @@es_client = Elasticsearch::Client.new(
    request_timeout: 15, retry_on_status: [403], retry_on_failure: 2,
    cloud_id: ENV['ES_CLOUD_ID'],
    api_key: { id: ENV['ES_API_KEY_ID'], api_key: ENV['ES_API_KEY'] }
  )

  Stretchy.client = @@es_client

  ##
  # :section: Basic ES commands

  ##
  # Pings ES to check whether it is up.
  def ping_es
    handle_es_errors(occured_when: 'pinging ES') do
      Timeout.timeout(TIMEOUT) do
        Helpers::ApiResponse.new(status: :success, body: @@es_client.ping)
      end
    end
  end

  ##
  # Checks for ES stats.
  #
  # Used in Manage::ElasticsearchIndexesController#index.
  def es_stats
    handle_es_errors(occured_when: 'fetching ES stats') do
      Timeout.timeout(TIMEOUT) do
        Helpers::ApiResponse.new(status: :success, body: @@es_client.indices.stats)
      end
    end
  end

  ##
  # Checks for the ES cluster health status.
  #
  # Used in WatchStream#check_es, Manage::ElasticsearchIndexesController#index.
  def es_health
    handle_es_errors(occured_when: 'fetching ES cluster health') do
      Timeout.timeout(TIMEOUT) do
        Helpers::ApiResponse.new(status: :success, body: @@es_client.cluster.health)
      end
    end
  end

  ##
  # :section: ES calls

  ##
  # {Date Histogram}[https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-bucket-datehistogram-aggregation.html]
  # aggregation.
  #
  # Used in ApisController#get_stream_graph_keywords_data, which is leveraged in the +StreamGraphKeywords+ vizualisation
  # (+app/javascript/components/stream_graph_keywords/StreamGraphKeywords.js+).
  #
  # [keywords]
  #   Array of keywords for a {Match}[https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-match-query.html]
  #   query (aggregation is performed on top of that match).
  # [not_keywords]
  #   Array of keywords to exclude.
  # [start_date, end_date]
  #   +start_date+ < query date range < +end_date+, in {Date Math}[https://www.elastic.co/guide/en/elasticsearch/reference/current/common-options.html#date-math]
  #   or +strict_date_optional_time+ format.
  # [interval]
  #   +calendar_interval+ for the date histogram aggregation.
  # [use_cache]
  #   Enable Rails cache.
  def date_histogram(
    index:, keywords: [], not_keywords: [],
    start_date: 'now-20y', end_date: 'now', interval: '1M', use_cache: true
  )
    definition = {
      size: 0,
      aggs: { all_data_agg: { date_histogram: { field: 'created_at', calendar_interval: interval } } },
      query: { bool: { filter: [{ range: { created_at: { gte: start_date, lte: end_date } } }] } }
    }

    definition = add_keywords(definition, keywords)
    definition = add_keywords(definition, not_keywords)

    cache_key = "date-histogram-#{method_args_from_parameters(method_binding: binding).except(use_cache)}"
    cached(cache_key, use_cache: use_cache) do
      handle_es_errors(occured_when: 'aggregating tweets by keywords on ES') do
        Timeout.timeout(TIMEOUT) do
          result = @@es_client.search index: index, body: definition
          Helpers::ApiResponse.new(status: :success, body: result['aggregations']['all_data_agg']['buckets'])
        end
      end
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
        Timeout.timeout(TIMEOUT) do
          result = @@es_client.search index: index, body: definition
          Helpers::ApiResponse.new(status: :success, body: result['aggregations']['hist_agg']['buckets'])
        end
      end
    end
  end

  def get_geo_sentiment(**kwargs)
    raise NotImplementedError
  end

  def predictions(
    index:, question_tag:, answer_tags:, run_name:,
    start_date: 'now-20y', end_date: 'now', interval: 'month', include_retweets: true, use_cache: true
  )
    aggs = {
      predictions: { date_histogram: { field: 'created_at', calendar_interval: interval } }
    }

    cache_key = "predictions-#{method_args_from_parameters(method_binding: binding).except(use_cache)}"
    cached(cache_key, use_cache: use_cache) do
      handle_es_errors(occured_when: 'aggregating predictions on ES') do
        predictions = {}
        answer_tags.each do |answer_tag|
          definition = aggregation_query(aggs, question_tag, run_name, start_date, end_date, include_retweets)
          definition[:query][:bool][:filter] << { term: { "predictions.#{question_tag}.endpoints.#{run_name}.label": answer_tag } }
          result = @@es_client.search index: index, body: definition
          predictions[answer_tag] = result['aggregations']['predictions']['buckets']
        end
        Timeout.timeout(TIMEOUT) do
          Helpers::ApiResponse.new(status: :success, body: predictions)
        end
      end
    end
  end

  def get_streaming_email_status(type: 'weekly')
    raise NotImplementedError
  end

  ##
  # Trending tokens using ES
  # {Significant Text}[https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-bucket-significanttext-aggregation.html]
  # and {Sampler}[https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-bucket-sampler-aggregation.html]
  # aggregations. Sampler is used to not overwhelm the system and for shorter waiting times.
  #
  # Used in ApisController#get_trending_topics, which is leveraged in the +StreamGraphKeywords+ vizualisation
  # (+app/javascript/components/stream_graph_keywords/StreamGraphKeywords.js+).
  # [size]
  #   How many trending tokens to return.
  # [start_date, end_date]
  #   +start_date+ < query date range < +end_date+, in {Date Math}[https://www.elastic.co/guide/en/elasticsearch/reference/current/common-options.html#date-math]
  #   or +strict_date_optional_time+ format.
  # [use_cache]
  #   Enable Rails cache.
  def trending_tokens(index:, size: 10, start_date: 'now-2w', end_date: 'now', use_cache: true)
    definition = {
      size: 0, query: { range: { created_at: { gte: start_date, lte: end_date } } },
      aggs: { sample: {
        sampler: { shard_size: 100_000 },
        aggs: { trending_tokens: { significant_text: { field: 'text' } } }
      } }
    }

    cache_key = "trending-tokens-#{method_args_from_parameters(method_binding: binding).except(use_cache)}"
    cached(cache_key, use_cache: use_cache) do
      handle_es_errors(occured_when: 'aggregating trending tokens on ES') do
        Timeout.timeout(TIMEOUT) do
          result = @@es_client.search index: index, body: definition
          tokens = result['aggregations']['sample']['trending_tokens']['buckets'][0..size - 1].map { |d| d['key'] }
          Helpers::ApiResponse.new(status: :success, body: tokens)
        end
      end
    end
  end

  ##
  # Trending tweets within a specified datetime window using ES {Terms}[https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-bucket-terms-aggregation.html]
  # aggregation.
  #
  # Used in ApisController#get_trending_tweets, which is leveraged in the +StreamGraphKeywords+ vizualisation
  # (+app/javascript/components/stream_graph_keywords/StreamGraphKeywords.js+).
  #
  # [keywords]
  #   List of keywords for a {Match}[https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-match-query.html]
  #   query (aggregation is performed on top of that match).
  # [start_date, end_date]
  #   +start_date+ < query date range < +end_date+, in {Date Math}[https://www.elastic.co/guide/en/elasticsearch/reference/current/common-options.html#date-math]
  #   or +strict_date_optional_time+ format.
  # [size]
  #   How many trending tweets to return.
  # [min_doc_count]
  #   Minimum retweets a tweet needs to get to be considered for this query.
  # [use_cache]
  #   Enable Rails cache.
  def trending_tweets(
    index:, keywords: [], start_date: 'now-2w', end_date: 'now',
    size: 10, min_doc_count: 1, use_cache: true
  )
    definition = {
      size: 0,
      query: { bool: { must: [range: { created_at: { gte: start_date, lte: end_date } }] } },
      aggs: {
        trending_tweets: { terms: { field: 'retweeted_status_id', size: size, min_doc_count: min_doc_count } }
      }
    }
    definition = add_keywords(definition, keywords)

    cache_key = "trending-tweets-#{method_args_from_parameters(method_binding: binding).except(use_cache)}"
    cached(cache_key, use_cache: use_cache) do
      handle_es_errors(occured_when: 'aggregating trending tweets on ES') do
        Timeout.timeout(TIMEOUT) do
          result = @@es_client.search index: index, body: definition
          tweets = result['aggregations']['trending_tweets']['buckets'].map { |d| d['key'] }
          Helpers::ApiResponse.new(status: :success, body: tweets)
        end
      end
    end
  end

  ##
  # Checks whether the ES streams are runnning.
  #
  # Used in WatchStream#check_stream.
  def stream_activity(es_activity_threshold_min: 10)
    handle_es_errors(occured_when: 'counting ES activity') do
      Timeout.timeout(TIMEOUT) do
        query = { query: { range: { created_at: { gte: "now-#{es_activity_threshold_min}m", lt: 'now' } } } }
        Helpers::ApiResponse.new(status: :success, body: @@es_client.count({ body: query }))
      end
    end
  end

  ##
  # Fetches tweets for annotations for Project s with the +stream+ annotation mode.
  #
  # Calls sequence: QuestionSequencesController#show -> Project#tweet -> ElasticsearchApi#tweets.
  #
  # [user_id]
  #   Current user ID to exclude tweets that the user has already annotated.
  # [new_prob]
  #   Probability to get a new tweet, not an already annotated one.
  # [start_date, end_date]
  #   +start_date+ < query date range < +end_date+
  # [max_assignments]
  #   Maximum amount of users to annotate one tweet.
  # [max_validations]
  #   Output size of the search query, representing the capacity for tweet validations down the line
  #   (in Project#tweet).
  def tweets(
    index:, user_id: 0, new_prob: 0.5, start_date: 'now-1w', end_date: 'now', max_assignments: 2, max_validations: 5
  )
    query_new = { bool: { must_not: [{ exists: { field: 'annotations' } }] } }
    query_not_finished = { bool: {
      filter: [{ "script": {
        "script": "doc.containsKey('annotations.user_id') && doc['annotations.user_id'].size() > 0 && " \
                  "doc['annotations.user_id'].size() <= #{max_assignments}"
      } }],
      must_not: [{ terms: { 'annotations.user_id': [user_id] } }]
    } }

    query_pipeline = lambda do |query, index|
      query = sample_predictions_definition(
        recent_predictions_query(query, start_date: start_date, end_date: end_date)
      )
      handle_es_errors(occured_when: 'fetching a new tweet from ES') do
        Timeout.timeout(TIMEOUT) do
          @@es_client.search(index: index, size: max_validations, body: query)['hits']['hits']
        end
      end
    end

    rand_num = rand
    # First try to get annotated tweets that are not finished
    tweets = rand_num > new_prob ? query_pipeline.call(query_not_finished, index) : query_pipeline.call(query_new, index)
    return tweets if tweets.is_a?(Helpers::ApiResponse) && tweets.error?

    # If no tweets returned for query_not_finished, try query_new
    tweets = query_pipeline.call(query_new, index) if rand_num > new_prob && tweets.empty?
    return tweets if tweets.is_a?(Helpers::ApiResponse) && tweets.error?

    # Get necessary attributes of the received tweets
    tweets = tweets.map { |tweet| Helpers::Tweet.new(id: tweet['_id'], text: tweet['_source']['text'], index: tweet['_index']) }.compact
    Helpers::ApiResponse.new(status: :success, body: tweets)
  end

  ##
  # Updates a tweet on ES with a +user_id+ that annotated it.
  def update_tweet(index:, user_id:, tweet_id:)
    handle_es_errors(occured_when: 'updating a tweet on ES') do
      Timeout.timeout(TIMEOUT) do
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
  end

  private

  def add_keywords(definition, keywords)
    keywords.each do |keyword|
      if definition.dig(:query, :bool, :must).nil?
        definition[:query][:bool] = { must: [{ match: { text: keyword } }] }
      else
        definition[:query][:bool][:must] << { match: { text: keyword } }
      end
    end
    definition
  end

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
      Elasticsearch::Transport::Transport::Errors::NotFound,
      Timeout::Error
    ] => e
      Helpers::ErrorHandler.error_log_response(occured_when, e)
    end
  end

  def parse_dates(date)
    return date if date.include? 'now'

    Time.parse(date).utc.strftime(DATE_FORMAT)
  end

  def recent_predictions_query(query, start_date: 'now-1w', end_date: 'now')
    { bool: {
      must: [
        { range: { created_at: { gte: start_date, lte: end_date } } }
        # Wanted to sample based on the prediction outputs (active learning), but too complicated for now. Commented for later, if needed
        # { exists: { field: 'predictions' } }
      ],
      must_not: [
        { exists: { field: 'is_retweet' } },
        { exists: { field: 'has_quote' } }
      ]
    } }.deep_merge(query)
  end

  def sample_predictions_definition(query)
    { query: { function_score: { boost_mode: 'replace', functions: [{ random_score: {} }], query: query } } }
    # Wanted to sample based on the prediction outputs (active learning), but too complicated for now. Commented for later, if needed
    # {
    #   query: { function_score: {
    #     script_score: { script: {
    #       source: "if (_score > params['_source']['predictions']['#{question_tag}']['endpoints']['primary_probability'])" \
    #               ' { _score } else { 0 }'
    #     } },
    #     query: { function_score: { boost_mode: 'replace', functions: [{ random_score: {} }], query: query } }
    #   } }
    # }
  end
end
