class Project < ApplicationRecord
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
  after_commit :update_last_question_sequence_created_at, on: [:create, :destroy]

  # validations
  validates_presence_of :title, :description, :name
  validates_uniqueness_of :es_index_name, allow_nil: true
  validate :accessible_by_email_pattern_is_valid
  validates_with CsvValidator, fields: [:job_file]

  # scopes
  scope :for_current_locale, -> {where("'#{I18n.locale.to_s}' = ANY (locales)")}
  scope :primary, -> {where(primary: true).order({created_at: :desc})}

  # fields
  friendly_id :title, use: :slugged
  enum storage_mode: [:'s3-es', :'s3-es-no-retweets', :s3, :test_mode]
  enum image_storage_mode: [:inactive, :active, :avoid_possibly_sensitive]
  enum annotation_mode: [:stream, :local], _suffix: true
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
    if active_question_sequence_id == 0
      id
    else
      active_question_sequence_id
    end
  end

  def active_question_sequence_project
    if active_question_sequence_id == 0
      self
    else
      Project.find(active_question_sequence_id)
    end
  end

  def num_annotations
    question_sequences.map{|project| project.results.num_annotations}.sum
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
        match_ids.push project.id if project.accessible_by_email_pattern.length == 0
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
      accessible_by_email_pattern.length != 0
    else
      # user is signed in, decide on access restrictions
      if accessible_by_email_pattern.length == 0
        false
      else
        regexp = /#{accessible_by_email_pattern.join('|')}/
        user.email.match?(regexp)
      end
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
      question_cols = ['id', 'question', 'instructions']
      csv << question_cols
      questions.each do |question|
        csv << question.attributes.values_at(*question_cols)
      end
      # answers
      csv << ['Answers']
      answer_cols = ['id', 'answer']
      csv << answer_cols
      questions.each do |question|
        question.answers.each do |answer|
          csv << answer.attributes.values_at(*answer_cols)
        end
      end
    end
  end

  def self.is_up_to_date(remote_config)
    # test if given stream configuration is identical to projects
    return false if remote_config.nil?
    return false if remote_config.length != Project.primary.where(active_stream: true).count
    remote_config.each do |c|
      p = Project.find_by(slug: c['slug'])
      return false if p.nil?
      ['keywords', 'lang', 'locales'].each do |prop|
        return false if p[prop].nil? or c[prop].nil?
        return false if p[prop].sort != c[prop].sort
      end
      ['es_index_name', 'storage_mode', 'image_storage_mode', 'compile_trending_tweets', 'compile_trending_topics', 'model_endpoints', 'compile_data_dump_ids'].each do |prop|
        return false if p[prop].nil? or c[prop].nil?
        return false if p[prop] != c[prop]
      end
    end
    return true
  end

  def results_to_csv(type: 'public-results')
    model_cols=['id', 'question_id', 'answer_id', 'tweet_id', 'user_id', 'project_id', 'flag', 'created_at']
    added_cols = ['question_tag', 'answer_tag', 'text', 'user_name', 'total_duration_ms', 'question_sequence_name', 'full_log']
    tmp_file_path = "/tmp/csv_upload_#{SecureRandom.hex}.csv"
    if type == 'public-results'
      results_ = results.public_res_type
    elsif type == 'other-results'
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
        if not log.nil? and log.has_key?('totalDurationQuestionSequence')
          total_duration_ms = log['totalDurationQuestionSequence']
        else
          total_duration_ms = 0
        end
        row += [
          result.question.tag,
          result.answer.tag,
          tweet_text,
          result.user.username,
          total_duration_ms,
          result.project.question_sequence_name,
          log&.to_json
        ]
        csv << row
      end
    end
    return tmp_file_path
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
    if accessible_by_email_pattern.present?
      unless accessible_by_email_pattern.all? {|p| p.include?('@')}
        errors.add(:accessible_by_email_pattern, 'Patterns need to be email patterns including "@"')
      end
    end
  end

  def tweet(user_id: nil, test_mode: false)
    if stream_annotation_mode?
      # Get a recent tweet from the streaming queue
      tweet = tweet_stream(user_id)
      add_to_public_tweets(tweet) unless test_mode
      tweet.id.to_s
    elsif local_annotation_mode?
      # Fetch tweet from a pool of tweets stored in the public_tweets table
      public_tweet = tweet_local(user_id)
      public_tweet&.tweet_id&.to_s
    else
      raise ArgumentError 'Unsupported annotation mode'
    end
  end

  def add_endpoint(endpoint_name, question_tag, model_type, run_name)
    return if endpoint_name.nil?
    return if has_endpoint_for_question_tag(endpoint_name, question_tag)
    existing_endpoints = active_endpoints(question_tag)
    existing_endpoints[endpoint_name] = {'model_type': model_type, 'run_name': run_name}
    if existing_endpoints.length == 1
      # first time we add an endpoint -> make it primary
      model_endpoints[question_tag] = {'active': existing_endpoints, 'primary': endpoint_name}
    else
      model_endpoints[question_tag]['active'] = existing_endpoints
    end
    save
  end

  def remove_endpoint(endpoint_name, question_tag)
    return if endpoint_name.nil?
    return unless has_endpoint_for_question_tag(endpoint_name, question_tag)
    existing_endpoints = active_endpoints(question_tag)
    existing_endpoints.delete(endpoint_name)
    if existing_endpoints.length == 0
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
      if r['Tags']['project_name'] == es_index_name
        models_remote.push(r['ModelName'])
      end
    end
    resp_model_endpoints = {}
    found_change = false
    model_endpoints.each do |question_tag, active_endpoints|
      _active_endpoints = active_endpoints['active']
      primary_endpoint = active_endpoints['primary']
      _active_endpoints.each do |model_name, model_info_obj|
        if not models_remote.include?(model_name)
          # remote model was removed, update local config
          _active_endpoints.delete(model_name)
          found_change = true
          if model_name == primary_endpoint
            # deleted model was primary endpoint
            if _active_endpoints.length > 0
              # assign "next" active endpoint as primary endpoint
              primary_endpoint = _active_endpoints.keys[0]
            end
          end
        end
      end
      if _active_endpoints.length > 0
        model_endpoints[question_tag]['active'] = _active_endpoints
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

  def has_endpoint_for_question_tag(endpoint_name, question_tag)
    return false unless model_endpoints.key?(question_tag)
    return false unless model_endpoints[question_tag].key?('active')
    return false unless model_endpoints[question_tag]['active'].include?(endpoint_name)
    true
  end

  def is_primary_endpoint_for_question_tag(endpoint_name, question_tag)
    return false unless has_endpoint_for_question_tag(endpoint_name, question_tag)
    model_endpoints[question_tag]['primary'] == endpoint_name
  end

  def make_primary_endpoint(endpoint_name, question_tag)
    model_endpoints[question_tag]['primary'] = endpoint_name
    save
  end

  private

  def add_to_public_tweets(tweet)
    public_tweets.where(tweet_id: tweet.id).first_or_create(tweet_text: tweet.text)
  end

  def tweet_local(user_id)
    public_tweet = public_tweets.not_assigned_to_user(user_id, id).may_be_available&.first
    unless public_tweet.present?
      Rails.logger.error 'Could not find a suitable public tweet for annotation. Fetching a random tweet instead.'
      public_tweet = random_tweet
    end
    public_tweet
  end

  def tweet_stream(user_id)
    api = AwsApi.new
    tweet = nil # Need to define tweet outside the loop to then be returned outside the loop
    trials = 0
    loop do
      trials += 1
      if trials > MAX_COUNT_REFETCH
        ErrorLogger.error 'The number of trials exceeded when trying to fetch a new tweet from the API. Showing a random tweet instead.'
        return random_tweet
      end
      tweet = handle_error(error_return_value: false) do
        api.tweet(index: es_index_name, user_id: user_id)
      end
      if tweet == false
        e = tweet.error
        Rails.logger.info "Trial #{trials}. #{e.class}: #{e.message}."
      elsif !TweetValidation.tweet_is_valid?(tweet.id)
        Rails.logger.info "Trial #{trials}. The tweet #{tweet.id} is invalid and will be removed. Fetching a new tweet instead."
      end
    end
    { tweet_id: tweet.id, tweet_text: tweet.text }
  end

  def random_tweet
    return { tweet_id: '20', tweet_text: nil } if Result.count.zero?

    results_ = results.count.zero? ? Result.all : results
    tweet_id = nil # Need to define tweet outside the loop to then be returned outside the loop
    trials = 0
    loop do
      trials += 1
      if trials > MAX_COUNT_REFETCH
        ErrorLogger.error 'The number of trials exceeded when trying to fetch a random tweet. Showing a default tweet instead.'
        return { tweet_id: '20', tweet_text: nil }
      end
      Result.uncached do
        tweet_id = results_.limit(1000).order(Arel.sql('RANDOM()')).first&.tweet_id&.to_s
      end
      unless TweetValidation.tweet_is_valid?(tweet_id)
        Rails.logger.info "Trial #{trials + 1}. The tweet #{tweet_id} is invalid, trying again."
      end
    end
    { tweet_id: tweet_id, tweet_text: nil }
  end
end
