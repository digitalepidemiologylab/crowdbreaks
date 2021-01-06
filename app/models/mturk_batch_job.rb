class MturkBatchJob < ApplicationRecord
  include ActiveModel::Validations
  include S3UploadableAssociation
  include CsvFileHandler

  has_many :tasks, dependent: :delete_all
  has_many :mturk_tweets, dependent: :delete_all
  has_many :results, through: :tasks
  belongs_to :project
  belongs_to :mturk_worker_qualification_list

  validates :name, presence: true, uniqueness: {message: "Name must be unique"}
  validates_presence_of :description, :title, :keywords, :lifetime_in_seconds, :assignment_duration_in_seconds, :project, :reward
  validates_inclusion_of :sandbox, in: [true, false]
  validates_inclusion_of :minimal_approval_rate, in: 0..100, message: 'Minimal approval rate needs to be between 0 and 100', allow_nil: true
  validates_inclusion_of :number_of_assignments, in: 1..100, message: 'Number assignments cannot be 1 or >100'
  validates_with CsvValidator, fields: [:job_file]
  validates_with HitTypeValidator, on: :create
  validates_with QualificationListValidator

  enum check_availability: [:before, :after, :before_and_after, :never], _prefix: true

  attr_accessor :cloned_name

  def workers
    MturkWorker.where(id: tasks&.select(:mturk_worker_id))
  end

  def num_tasks
    tasks.count
  end

  def num_tweets
    mturk_tweets.count
  end

  def num_tasks_where(status)
    tasks.where(lifecycle_status: status).count
  end

  def percentage_completed
    total_done = num_tasks_where(:completed)
    return 0 if num_tasks == 0
    (total_done.to_f / num_tasks.to_f * 100.0).to_i
  end

  def is_submitted?
    case status
    when 'in progress', 'completed'
      true
    else
      false
    end
  end

  def status
    return 'deleting' if marked_for_deletion
    return 'processing' if processing
    return 'empty' if num_tweets == 0
    return 'unsubmitted' if num_tasks_where(:unsubmitted) == num_tasks
    return 'completed' if num_tasks_where(:completed) == num_tasks
    'in progress'
  end

  def cleanup(destroy_results: false)
    # Delete all associated HITs on Mturk
    Rails.logger.info "Cleaning up MturkBatchJob..."
    tasks.each do |task|
      Rails.logger.info "Cleaning up Task #{task.id}..."
      task.delete_hit
      if destroy_results
        task.results.delete_all
      else
        task.results.update_all({task_id: nil})
      end
    end
  end

  def exclude_blacklisted_workers
    # Exclude all blacklisted workers from this batch job
    MturkWorker.blacklisted_status.each do |mturk_worker|
      mturk_worker.exclude_worker(self)
    end
  end

  def get_qualification
    if qualification_type_id.present?
      Rails.logger.info "Retrieving qualification type #{qualification_type_id}..."
      Mturk.new.get_qualification_type(qualification_type_id)
    else
      nil
    end
  end

  def remove_qualification
    if self.qualification_type_id.present?
      Rails.logger.info "Remove qualification type #{self.qualification_type_id}..."
      Mturk.new.delete_qualification_type(self.qualification_type_id)
    end
  end

  def default_mturk_instructions
    default_instructions_path = File.join(Rails.root, 'app/views/mturk/default_mturk_instructions.md')
    File.read(default_instructions_path)
  end

  def sanitize_keywords!
    # enforce uniqueness of HIT type ID
    self.keywords ||= ''
    self.keywords += ', ' + SecureRandom.hex[0..6]
  end

  def results_to_csv
    model_cols=['id', 'question_id', 'answer_id', 'tweet_id', 'project_id', 'task_id', 'flag', 'created_at']
    added_cols = ['worker_id', 'text', 'question_tag', 'answer_tag', 'total_duration_ms', 'question_sequence_name', 'full_log']
    tmp_file_path = "/tmp/csv_upload_#{SecureRandom.hex}.csv"
    CSV.open(tmp_file_path, 'w') do |csv|
      csv << model_cols + added_cols
      results.find_each do |result|
        row = result.attributes.values_at(*model_cols)
        log = result.question_sequence_log&.log
        if not log.nil? and log.has_key?('totalDurationQuestionSequence')
          total_duration_ms = log['totalDurationQuestionSequence']
        else
          total_duration_ms = 0
        end
        row += [
          result.task&.mturk_worker&.worker_id,
          result.task&.mturk_tweet&.tweet_text,
          result.question&.tag,
          result.answer&.tag,
          total_duration_ms,
          result.project.question_sequence_name,
          log&.to_json
        ]
        csv << row
      end
    end
    return tmp_file_path
  end

  private

end
