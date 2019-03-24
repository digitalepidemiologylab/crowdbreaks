class LocalBatchJob < ApplicationRecord
  include ActiveModel::Validations
  include S3Uploadable

  extend FriendlyId
  friendly_id :name, use: :slugged

  has_and_belongs_to_many :users
  has_many :local_tweets, dependent: :delete_all
  belongs_to :project
  has_many :results

  validates :name, presence: true, uniqueness: {message: "Name must be unique"}
  validates_presence_of :project
  validates_with CsvValidator, fields: [:job_file]

  enum processing_mode: {default: 0, test: 1}, _suffix: :processing_mode

  attr_accessor :job_file


  def completed_by
    return [] unless status == 'ready'
    completed_by = []
    total_count = local_tweets.may_be_available.count
    users.each do |u|
      user_count = results.counts_by_user(u.id)
      completed_by.push(u.username) if user_count == total_count
    end
    completed_by
  end

  def cleanup
    local_tweets.delete_all
  end

  def status
    return 'processing' if processing
    return 'deleting' if deleting
    return 'empty' if local_tweets.count == 0
    'ready'
  end

  def allows_user?(user_id)
    return false if user_id.nil?
    users.exists?(user_id) ? true : false
  end

  def default_instructions
    "# Instructions for this task"
  end

  def results_to_csv
    model_cols=['id', 'question_id', 'answer_id', 'tweet_id', 'user_id', 'project_id', 'flag', 'created_at']
    added_cols = ['log', 'text', 'user_name']
    tmp_file_path = "/tmp/csv_upload_#{SecureRandom.hex}.csv"
    CSV.open(tmp_file_path, 'w') do |csv|
      csv << model_cols + added_cols
      results.each do |result|
        row = result.attributes.values_at(*model_cols)
        tweet_text = result.local_batch_job.local_tweets.find_by(tweet_id: result.tweet_id)&.tweet_text
        row += [result.question_sequence_log&.log&.to_json,
                tweet_text,
                result.user.username]
        csv << row
      end
    end
    return tmp_file_path
  end
end
