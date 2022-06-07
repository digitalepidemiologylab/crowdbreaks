class LocalBatchJob < ApplicationRecord
  include ActiveModel::Validations
  include S3UploadableAssociation
  include CsvFileHandler

  extend FriendlyId
  friendly_id :name, use: :slugged

  has_and_belongs_to_many :users
  belongs_to :project
  belongs_to :mturk_auto_batch
  has_many :local_tweets, dependent: :delete_all
  has_many :results

  validates :name, presence: true, uniqueness: { message: 'Name must be unique' }
  validates :name, format: {
    with: /\A[a-z0-9_]+\z/, message: 'Name must only include small letters, numbers, and underscores'
  }
  validates_presence_of :project
  validates_with CsvValidator, fields: [:job_file]
  validate :mturk_auto_batch_for_auto_true

  enum processing_mode: { default: 0, test: 1 }, _suffix: :processing_mode
  enum check_availability: %i[do_not do], _suffix: true
  enum tweet_display_mode: %i[hide_card_hide_conversation show_card_hide_conversation hide_card_show_conversation show_card_show_conversation]
  enum annotation_display_mode: %i[default skip_final]

  attr_accessor :job_file

  def allows_user?(user_id)
    return false if user_id.nil?

    users.exists?(user_id) ? true : false
  end

  def cleanup
    local_tweets.delete_all
  end

  def completed_by
    return [] unless status == 'ready'

    completed_by = []
    total_count = local_tweets.may_be_available.count
    users.each do |u|
      user_count = results.counts_by_user(u.id)
      completed_by.push << u.username if user_count == total_count
    end
    completed_by
  end

  def default_instructions
    '# Instructions for this task'
  end

  def progress_by_user(user)
    return 0 unless users.where(id: user.id).exists?

    total_count = local_tweets.may_be_available.count
    return 0 if total_count.zero?

    user_count = results.counts_by_user(user.id)
    (100 * user_count / total_count).to_i
  end

  def results_to_csv
    model_cols = %w[id question_id answer_id tweet_id user_id project_id flag created_at']
    added_cols = %w[text question_tag answer_tag user_name total_duration_ms question_sequence_name full_log]
    tmp_file_path = "/tmp/csv_upload_#{SecureRandom.hex}.csv"
    CSV.open(tmp_file_path, 'w') do |csv|
      csv << model_cols + added_cols
      results.find_each do |result|
        row = result.attributes.values_at(*model_cols)
        tweet_text = result.local_batch_job.local_tweets.find_by(tweet_id: result.tweet_id)&.tweet_text
        log = result.question_sequence_log&.log
        total_duration_ms = !log.nil? && log.key?('totalDurationQuestionSequence') ? log['totalDurationQuestionSequence'] : 0
        row += [
          tweet_text,
          result.question.tag,
          result.answer.tag,
          result.user.username,
          total_duration_ms,
          result.project.question_sequence_name,
          log&.to_json
        ]
        csv << row
      end
    end
    tmp_file_path
  end

  def status
    return 'processing' if processing
    return 'deleting' if deleting

    'ready'
  end

  private

  def mturk_auto_batch_for_auto_true
    return if auto == false
    return if auto == true && !mturk_auto_batch.nil?

    errors.add(:base, 'No mturk_auto_batch for an local_batch_job.auto == true.')
  end
end
