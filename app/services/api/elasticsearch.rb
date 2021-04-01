require 'stretchy'

module Elasticsearch
  extend ActiveSupport::Concern

  region = 'eu-central-1'
  service = 'es'

  client = Elasticsearch::Client.new(url: ENV['ES_HOST_PORT']) do |f|
    f.request :aws_sigv4,
      service: service,
      region: region,
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
  end

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
    handle_error_notification do
      name = params.delete('name')
      client.indices.create(index: name, body: params.to_json, headers: FlaskApi::JSON_HEADER)
    end
  end

  def get_tweet(es_index_name, user_id: nil, new_prob: 0.05)
    query_new = Stretchy.query.not.query(exists: { field: 'annotations' })

    query_not_finished = Stretchy.query.query(
      exists: { field: 'annotations' }
    ).not.query(
      exists: { field: 'annotations_finished' }
    )

    loop do
      try_again = false
      if rand > new_prob
        tweet = get_nested_query(query_not_finished).results[0]
      else
        tweet = get_nested_query(query_new).results[0]
        tweet.fetch('annotations', []).each do |annotation|
          if annotation['author'] == user_id
            try_again = true
          end
        end
      end
      break if try_again == false
    end
    tweet
  end

  def update_tweet(es_index_name, user_id, tweet_id)
    handle_error do
      client.update(
        {
          id: tweet_id,
          type: '_doc',
          index: es_index_name,
          refresh: true,
          body: {
            script: {
              source: 'ctx._source.annotations.add(params.annotation)',
              lang: 'painless',
              params: {
                annotation: { author: user_id }
              }
            }
          }
        }
      )
    end
  end

  # elasticsearch - all data
  def get_all_data(index, options={})
    start_date = parse_dates(options.fetch(:start_date, 'now-20y'))
    end_date = parse_dates(options.fetch(:start_date, 'now'))
    keywords = options.fetch(:keywords, [])
    not_keywords = options.fetch(:not_keywords, [])

    query = Stretchy.query(
      index: index,
      aggs: {
        sentiment: {
          date_histogram: {
            field: 'created_at',
            interval: options.fetch('interval', 'month'),
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
  def get_predictions(index:, question_tag:, answer_tags:, run_name: '', options={}, use_cache=true)
    # use_cache -- deprecated
    start_date = parse_dates(options.fetch(:start_date, 'now-20y'))
    end_date = parse_dates(options.fetch(:start_date, 'now'))
    include_retweets = options.fetch(:include_retweets, true)

    query = Stretchy.query(
      index: index,
      aggs: {
        prediction_agg: {
          date_histogram: {
            field: 'created_at',
            interval: options.fetch('interval', 'month'),
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

  def get_avg_label_val(index, question_tag, run_name=nil, options={}, use_cache=true)
    start_date = parse_dates(options.fetch(:start_date, 'now-20y'))
    end_date = parse_dates(options.fetch(:start_date, 'now'))

    with_moving_average = options.fetch(:with_moving_average, nil)
    moving_average_window_size = options.fetch(:moving_average_window_size, 10)
    interval = options.fetch(:interval, 'month')
    include_retweets = options.fetch(:include_retweets, true)

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

  def get_trending_tweets(index, options={})
    # project_slug -> index
    start_date = parse_dates(options.fetch(:start_date, 'now-1w'))
    end_date = parse_dates(options.fetch(:start_date, 'now'))

    size = options.fetch(:size, 10)
    min_doc_count = options.fetch(:min_doc_count, 10)

    query = Stretchy.query(
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
    ).fields('aggregations.trending_tweets').limit(0).range(
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

  def handle_error(error_return_value: nil)
    begin
      yield
    rescue StandardError => e
      error_return_value
    end
  end

  def handle_error_notification(message: 'An error occured')
    begin
      yield
    rescue StandardError => e
      Hashie::Mash.new({success: false, parsed_response: message, code: 400})
    end
  end
end
