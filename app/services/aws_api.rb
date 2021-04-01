require 'elasticsearch'
require 'faraday_middleware/aws_sigv4'
require 'stretchy'

class AwsApi
  include Ml
  include Pipeline
  include Elasticsearch

  def get_trending_tweets(project_slug, options={})
    resp = self.class.get('/trending_tweets/'+project_slug, body: options.to_json, timeout: 10, headers: JSON_HEADER)
    resp.parsed_response
  end

  def get_trending_topics(project_slug, options={})
    resp = self.class.get('/trending_topics/'+project_slug, body: options.to_json, timeout: 10, headers: JSON_HEADER)
    resp.parsed_response
  end

  # elasticsearch - all data
  def get_all_data(index, options={}, use_cache=true)
    cache_key = "get-all-data-#{index}-#{options.to_s}"
    cached(cache_key, use_cache=use_cache) do
      resp = self.class.get('/data/all/'+index, body: options.to_json, timeout: 20, headers: JSON_HEADER)
      resp.parsed_response
    end
  end

  # elasticsearch - sentiment data
  def get_predictions(index, question_tag, answer_tags, run_name='', options={}, use_cache=true)
    cache_key = "get-predictions-#{index}-#{question_tag}-#{run_name}-#{answer_tags&.join('_')}-#{options.to_s}"
    body = {
      question_tag: question_tag,
      answer_tags: answer_tags,
      run_name: run_name,
      **options
    }
    cached(cache_key, use_cache=use_cache) do
      resp = self.class.post('/data/predictions/'+index, body: body.to_json, timeout: 60, headers: JSON_HEADER)
      resp.parsed_response
    end
  end

  def get_avg_label_val(index, question_tag, run_name='', options={}, use_cache=true)
    cache_key = "get-avg-label-val-#{index}-#{question_tag}-#{run_name}-#{options.to_s}"
    body = {
      question_tag: question_tag,
      run_name: run_name,
      **options
    }
    cached(cache_key, use_cache=use_cache) do
      resp = self.class.post('/data/average_label_val/'+index, body: body.to_json, timeout: 60, headers: JSON_HEADER)
      resp.parsed_response
    end
  end

  def get_geo_sentiment(options={})
    handle_error(error_return_value: []) do
      resp = self.class.get('/sentiment/geo', query: options, timeout: 20)
      JSON.parse(resp)
    end
  end

  # email status
  def get_streaming_email_status(type: 'weekly')
    options = {type: type}
    handle_error(error_return_value: '') do
      resp = self.class.get('/email/status', query: options, timeout: 20)
      resp.parsed_response
    end
  end


  private

  def get_nested_query(query, index, limit: 1)
    # Prioritize already annotated tweets (not enough times)
    query = query.range(
        # 2021-03-10T22:00:10.000Z
        created_at: {gte: (Time.now.utc - 60*60*24*14).strftime("%Y-%m-%dT%T.000Z")}
        # "%a %b %-d %T %z %Y" -- previous twitter strftime
      )
      .not.match(is_retweet: true)
      .not.match(has_quote: true)
      .query({
        "exists": {
          "field": "predictions"
        }
      })
      .boost(boost_mode: "replace").random(42)
      # .boost(script_score:
      #   {
      #     "script": {
      #       "source": "if (_score > 0.999999) { _score } else { 0 }"
      #     }
      #   })

    nested_query = {
      function_score: {
        script_score: {
          script: {
            source: "if (_score > params['_source']['predictions']['primary']) { _score } else { 0 }"
          }
        },
        query: query.request[:body][:query]
      }
    }

    query_full = Stretchy.query(index: index)
      .query(nested_query)
      .limit(limit).offset(0)
  end

  def cached(cache_key, use_cache=false, cache_duration=5.minutes)
    if use_cache
      if Rails.cache.exist?(cache_key)
        Rails.logger.info("Reading from cache key #{cache_key}")
        return Rails.cache.read(cache_key)
      else
        resp = yield
        has_error = false
        if resp.is_a? Hash
          if resp.key?('success')
            has_error = !resp['success']
          end
        end
        unless resp.nil? or resp == [] or resp == {} or has_error
          Rails.logger.info("Setting cache key #{cache_key}")
          Rails.cache.write(cache_key, resp, expires_in: cache_duration)
        end
        return resp
      end
    else
      # invalidate previous cache
      Rails.cache.delete(cache_key)
      return yield
    end
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
