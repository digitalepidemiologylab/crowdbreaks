class Project < ApplicationRecord
  include S3Uploadable
  include S3UploadableAssociation
  extend FriendlyId

  has_many :questions
  has_many :transitions
  has_many :results
  has_many :mturk_batch_jobs
  has_many :local_batch_jobs
  has_many :public_tweets

  # callbacks
  before_validation :normalize_blank_values

  # validations
  validates_presence_of :title, :description, :name
  validates_uniqueness_of :es_index_name, allow_nil: true
  validate :accessible_by_email_pattern_is_valid

  # scopes
  scope :for_current_locale, -> {where("'#{I18n.locale.to_s}' = ANY (locales)")}

  # fields
  friendly_id :title, use: :slugged
  enum storage_mode: [:'s3-es', :'s3-es-no-retweets', :s3, :test_mode]
  enum image_storage_mode: [:inactive, :active, :avoid_possibly_sensitive]
  translates :title, :description

  def display_name
    title
  end

  def to_label
    # display name for simple form select options
    if Project.where(name: name).count == 1
      name
    else
      # display project name with index based on created_at
      idx = Project.where(name: 'project_crispr').order(:created_at).pluck(:id).find_index(id) + 1
      "#{name} (#{idx})"
    end
  end

  def self.grouped_by_name(projects: nil)
    if projects.nil?
      projects = Project.all
    end
    grouped_projects = []
    projects.distinct.pluck(:name).each do |name|
      grouped_projects.push(Project.where(name: name).to_a)
    end
    grouped_projects
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
    return false if remote_config.length != Project.where(active_stream: true).count
    remote_config.each do |c|
      p = Project.find_by(slug: c['slug'])
      return false if p.nil?
      ['keywords', 'lang'].each do |prop|
        return false if p[prop].sort != c[prop].sort
      end
      ['es_index_name', 'storage_mode', 'image_storage_mode'].each do |prop|
        return false if p[prop] != c[prop]
      end
    end
    return true
  end

  def results_to_csv
    model_cols=['id', 'question_id', 'answer_id', 'tweet_id', 'user_id', 'project_id', 'flag', 'created_at']
    added_cols = ['question_tag', 'answer_tag', 'text', 'user_name', 'total_duration_ms', 'full_log']
    tmp_file_path = "/tmp/csv_upload_#{SecureRandom.hex}.csv"
    CSV.open(tmp_file_path, 'w') do |csv|
      csv << model_cols + added_cols
      results.public_res_type.find_each do |result|
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

  def accessible_by_email_pattern_is_valid
    if accessible_by_email_pattern.present?
      unless accessible_by_email_pattern.all? {|p| p.include?('@')}
        errors.add(:accessible_by_email_pattern, 'Patterns need to be email patterns including "@"')
      end
    end
  end
end
