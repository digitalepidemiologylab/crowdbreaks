class Project < ApplicationRecord
  include Response
  include S3Uploadable
  include S3UploadableAssociation
  include CsvFileHandler
  extend FriendlyId

  has_many :questions
  has_many :transitions
  has_many :results
  has_many :mturk_batch_jobs
  has_many :local_batch_jobs
  has_many :public_tweets, dependent: :destroy

  # callbacks
  before_validation :normalize_blank_values
  after_commit :update_last_question_sequence_created_at, on: %i[create destroy]

  # validations
  validates_presence_of :title, :description, :name
  validates_uniqueness_of :es_index_name, allow_nil: true
  validates_uniqueness_of :name
  validate :accessible_by_email_pattern_is_valid
  validates_with CsvValidator, fields: [:job_file]

  # scopes
  scope :for_current_locale, -> { where("'#{I18n.locale}' = ANY (locales)") }
  scope :primary, -> { where(primary: true).order({ created_at: :desc }) }

  # fields
  friendly_id :name, use: :slugged
  enum storage_mode: %i[s3-es s3-es-no-retweets s3 s3-no-retweets test_mode]
  enum image_storage_mode: %i[inactive active]
  enum annotation_mode: %i[stream local], _suffix: true
  translates :title, :description

  MAX_COUNT_REFETCH_DB = 10
  MAX_COUNT_REFETCH = 5

  def display_name
    title
  end

  def to_label
    # display name for simple form select options
    if primary?
      "#{name} (primary)"
    else
      "#{name} (#{question_sequence_name})"
    end
  end

  def num_question_sequences
    question_sequences.count
  end

  def active_question_sequence
    if active_question_sequence_id.zero?
      id
    else
      active_question_sequence_id
    end
  end

  def active_question_sequence_project
    if active_question_sequence_id.zero?
      self
    else
      Project.find(active_question_sequence_id)
    end
  end

  def num_annotations
    question_sequences.map { |project| project.results.num_annotations }.sum
  end

  def primary_project
    # in case of a project having multiple question sequences this method will return the original one
    Project.where(name: name, primary: true)&.first || self
  end

  def self.primary_project_by_name(name)
    where(primary: true, name: name)&.first
  end

  def question_sequences
    Project.where(name: name)
  end

  def self.accessible_by_user(user)
    projects = all
    match_ids = []
    if user.nil?
      # user is not signed in, only allow projects without any restrictions/patterns given
      projects.each do |project|
        match_ids.push project.id if project.accessible_by_email_pattern.empty?
      end
    else
      # user is signed in, decide on access restrictions
      projects.each do |project|
        regexp = /#{project.accessible_by_email_pattern.join('|')}/
        match_ids.push project.id if user.email.match?(regexp)
      end
    end
    projects.where(id: match_ids)
  end

  def accessible_by?(user)
    if user.nil?
      # user is not signed in, only allow projects without any restrictions/patterns given
      !accessible_by_email_pattern.empty?
    elsif accessible_by_email_pattern.empty?
      # user is signed in, decide on access restrictions
      false
    else
      regexp = /#{accessible_by_email_pattern.join('|')}/
      user.email.match?(regexp)
    end
  end

  def initial_question
    first_transition = transitions.find_by(from_question: nil)
    return nil if first_transition.nil?

    first_transition.to_question
  end

  def qs_to_csv
    CSV.generate do |csv|
      # questions
      csv << ['Questions']
      question_cols = %w[id question instructions]
      csv << question_cols
      questions.each do |question|
        csv << question.attributes.values_at(*question_cols)
      end
      # answers
      csv << ['Answers']
      answer_cols = %w[id answer]
      csv << answer_cols
      questions.each do |question|
        question.answers.each do |answer|
          csv << answer.attributes.values_at(*answer_cols)
        end
      end
    end
  end

  def self.up_to_date?(remote_config)
    # test if given stream configuration is identical to projects
    selected_params = %i[keywords lang locales es_index_name slug active storage_mode image_storage_mode model_endpoints]
    config = Project.primary.where(active_stream: true).to_json(only: selected_params)
    return false if remote_config.nil?

    remote_config.to_json == config

    # return false if remote_config.nil?
    # return false if remote_config.length != Project.primary.where(active_stream: true).count

    # remote_config.each do |c|
    #   p = Project.find_by(slug: c['slug'])
    #   return false if p.nil?

    #   puts p.to_json()

    #   %w[keywords lang locales].each do |prop|
    #     puts 'first check'
    #     return false if p[prop].nil? || c[prop].nil?
    #     return false if p[prop].sort != c[prop].sort
    #   end
    #   %w[slug active storage_mode image_storage_mode model_endpoints].each do |prop|
    #     puts 'second check'
    #     return false if p[prop].nil? || c[prop].nil?
    #     return false if p[prop] != c[prop]
    #   end
    # end
    # true
  end

  def results_to_csv(type: 'public-results')
    model_cols = %w[id question_id answer_id tweet_id user_id project_id flag created_at]
    added_cols = %w[question_tag answer_tag text user_name total_duration_ms question_sequence_name full_log]
    tmp_file_path = "/tmp/csv_upload_#{SecureRandom.hex}.csv"
    case type
    when 'public-results'
      results_ = results.public_res_type
    when 'other-results'
      results_ = results.other_res_type
    else
      raise "Unsupported results type #{type}"
    end
    CSV.open(tmp_file_path, 'w') do |csv|
      csv << model_cols + added_cols
      results_.find_each do |result|
        row = result.attributes.values_at(*model_cols)
        log = result.question_sequence_log&.log
        tweet_text = public_tweets.find_by(tweet_id: result.tweet_id)&.tweet_text
        total_duration_ms = !log.nil? && log.key?('totalDurationQuestionSequence') ? log['totalDurationQuestionSequence'] : 0
        row += [
          result.question.tag, result.answer.tag, tweet_text, result.user.username,
          total_duration_ms, result.project.question_sequence_name, log&.to_json
        ]
        csv << row
      end
    end
    tmp_file_path
  end

  def normalize_blank_values(columns: [:es_index_name])
    columns.each do |column|
      self[column].present? || self[column] = nil
    end
  end

  def update_last_question_sequence_created_at
    # update a column in the primary project whenever a project gets added or removed
    primary_project.update_attribute(:last_question_sequence_created_at, primary_project.question_sequences.pluck(:created_at).max)
  end

  def accessible_by_email_pattern_is_valid
    return unless accessible_by_email_pattern.present?
    return if accessible_by_email_pattern.all? { |p| p.include?('@') }

    errors.add(:accessible_by_email_pattern, 'Patterns need to be email patterns including "@"')
  end

  def tweet(user_id:, test_mode: false)
    # Rails.logger.info "Calling '#{__method__}' from '#{caller[0][/`.*'/][1..-2]}'"
    if stream_annotation_mode?
      # Get a recent tweet from the streaming queue
      tweet = test_mode ? tweet_stream(user_id, index: ES_TEST_INDEX_PATTERN) : tweet_stream(user_id)
      add_to_public_tweets(tweet.body) unless test_mode
      tweet
    elsif local_annotation_mode?
      # Fetch tweet from a pool of tweets stored in the public_tweets table
      tweet_local(user_id)
    else
      raise ArgumentError 'Unsupported annotation mode'
    end
  end

  def add_endpoint(endpoint_name, question_tag, model_type, run_name)
    return if endpoint_name.nil?
    return if endpoint_for_question_tag?(endpoint_name, question_tag)

    existing_endpoints = active_endpoints(question_tag)
    existing_endpoints[endpoint_name] = { model_type: model_type, run_name: run_name }
    if existing_endpoints.length == 1
      # first time we add an endpoint -> make it primary
      model_endpoints[question_tag] = { 'active': existing_endpoints, 'primary': endpoint_name }
    else
      model_endpoints[question_tag]['active'] = existing_endpoints
    end
    save
  end

  def remove_endpoint(endpoint_name, question_tag)
    return if endpoint_name.nil?
    return unless endpoint_for_question_tag?(endpoint_name, question_tag)

    existing_endpoints = active_endpoints(question_tag)
    existing_endpoints.delete(endpoint_name)
    if existing_endpoints.empty?
      model_endpoints.delete(question_tag)
    else
      model_endpoints[question_tag]['active'] = existing_endpoints
      if model_endpoints[question_tag]['primary'] == endpoint_name
        # removed endpoint was primary endpoint, set to different endpoint
        model_endpoints[question_tag]['primary'] = existing_endpoints.keys[0]
      end
    end
    save
  end

  def sync_endpoints_with_remote(resp)
    # If endpoint has been removed remotely (e.g. through dev/stg), remove it from projects
    models_remote = []
    resp.each do |r|
      models_remote.push(r[:model_name]) if r[:tags][:project_name] == es_index_name
    end
    found_change = false
    model_endpoints.each do |question_tag, active_endpoints|
      active_endpoints_ = active_endpoints['active']
      primary_endpoint = active_endpoints['primary']
      active_endpoints_.each do |model_name, _model_info_obj|
        next unless models_remote.include?(model_name)

        # remote model was removed, update local config
        active_endpoints_.delete(model_name)
        found_change = true
        # if the deleted model was a primary endpoint, assign the "next" active endpoint as primary endpoint
        primary_endpoint = active_endpoints_.keys[0] if model_name == primary_endpoint && !active_endpoints_.empty?
      end
      if !active_endpoints_.empty?
        model_endpoints[question_tag]['active'] = active_endpoints_
        model_endpoints[question_tag]['primary'] = primary_endpoint
      else
        model_endpoints.delete(question_tag)
      end
    end
    save if found_change
  end

  def active_endpoints(question_tag)
    return {} if model_endpoints[question_tag].nil?
    return {} if model_endpoints[question_tag]['active'].nil?

    model_endpoints[question_tag]['active']
  end

  def endpoint_for_question_tag?(endpoint_name, question_tag)
    return false unless model_endpoints.key?(question_tag)
    return false unless model_endpoints[question_tag].key?('active')
    return false unless model_endpoints[question_tag]['active'].include?(endpoint_name)

    true
  end

  def primary_endpoint_for_question_tag?(endpoint_name, question_tag)
    return false unless endpoint_for_question_tag?(endpoint_name, question_tag)

    model_endpoints[question_tag]['primary'] == endpoint_name
  end

  def make_primary_endpoint(endpoint_name, question_tag)
    model_endpoints[question_tag]['primary'] = endpoint_name
    save
  end

  private

  def add_to_public_tweets(tweet)
    public_tweets.where(tweet_id: tweet.id).first_or_create(tweet_text: tweet.text, tweet_index: tweet.index)
  end

  def tweet_local(user_id)
    public_tweet = public_tweets.not_assigned_to_user(user_id, id).has_tweet_index.may_be_available&.first
    unless public_tweet.present?
      return Helpers::ApiResponse.new(
        status: :fail, body: random_tweet,
        message: 'Could not find a suitable public tweet for annotation, showing a random tweet.'
      )
    end
    public_tweet = Helpers::Tweet(
      id: public_tweet[:tweet_id], text: public_tweet[:tweet_text], index: public_tweet[:tweet_index]
    )
    Helpers::ApiResponse.new(status: :success, body: public_tweet)
  end

  def tweet_stream(user_id, index: es_index_name)
    api = AwsApi.new
    get_tweet_from_api = lambda do |api, index, user_id|
      response = api.tweets(index: index, user_id: user_id)
      if response.error?
        ErrorLogger.error 'Did not manage to get a tweet from the stream, showing a random tweet.'
        return Helpers::ApiResponse.new(
          status: :fail, body: random_tweet,
          message: 'Did not manage to get a tweet from the stream, showing a random tweet.'
        )
      end
      response.body
    end

    cache_key = "tweets-from-stream-user-#{user_id}"
    if Rails.cache.exist?(cache_key)
      Rails.logger.info 'Reading from CACHE'
      tweets = Rails.cache.read(cache_key)
    else
      tweets = get_tweet_from_api.call(api, index, user_id)
    end

    tweets.each_with_index do |tweet, i|
      next unless TweetValidation.tweet_is_valid?(tweet.id)

      if tweets[i + 1..-1].length.positive?
        Rails.logger.info 'Writing to CACHE'
        Rails.cache.write(cache_key, tweets[i + 1..-1], expires_in: 5.minutes)
      else
        Rails.logger.info 'Deleting CACHE'
        Rails.cache.delete(cache_key)
      end
      return Helpers::ApiResponse.new(status: :success, body: tweet)
    end
    ErrorLogger.error 'The tweets from the stream are invalid, showing a random tweet.'
    Helpers::ApiResponse.new(
      status: :fail, body: random_tweet,
      message: 'The tweets from the stream are invalid, showing a random tweet.'
    )
  end

  def random_tweet(retries: MAX_COUNT_REFETCH)
    default_tweet = Helpers::Tweet.new(id: '20', text: 'Have not found a valid tweet ¯\_(ツ)_/¯', index: nil)
    return default_tweet if Result.count.zero?

    if retries.zero?
      Rails.logger.info 'The number of trials exceeded when trying to fetch a random tweet. Showing a default tweet instead.'
      return default_tweet
    end
    tweet_id = nil
    results_ = results.count.zero? ? Result.all : results
    Result.uncached do
      tweet_id = results_.limit(1000).order(Arel.sql('RANDOM()')).first&.tweet_id&.to_s
    end
    unless TweetValidation.tweet_is_valid?(tweet_id)
      Rails.logger.info "Retries left #{retries}/#{MAX_COUNT_REFETCH}. The tweet #{tweet_id} is invalid, trying again."
      random_tweet(retries: retries - 1)
    end
    Helpers::Tweet.new(id: tweet_id, text: nil, index: nil)
  end
end
