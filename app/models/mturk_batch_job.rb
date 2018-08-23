class MturkBatchJob < ApplicationRecord
  include ActiveModel::Validations

  has_many :tasks, dependent: :delete_all
  has_many :mturk_tweets, dependent: :delete_all
  belongs_to :project
  has_many :results, through: :tasks

  validates :name, presence: true, uniqueness: {message: "Name must be unique"}
  validates_presence_of :description, :title, :keywords, :lifetime_in_seconds, :assignment_duration_in_seconds, :project, :reward
  validates_inclusion_of :sandbox, in: [true, false]
  validates_inclusion_of :minimal_approval_rate, in: 0..100, message: 'Minimal approval rate needs to be between 0 and 100', allow_nil: true
  validates_inclusion_of :number_of_assignments, in: 1..100, message: 'Number assignments cannot be 1 or >100'
  validates_with CsvValidator, fields: [:job_file]
  validates_with HitTypeValidator


  attr_accessor :job_file

  def num_tasks
    tasks.count
  end

  def num_queued_tasks
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
    status == 'unsubmitted' ? false : true
  end

  def status
    return 'deleting' if marked_for_deletion
    return 'processing' if processing
    return 'empty' if num_queued_tasks == 0
    return 'unsubmitted' if num_tasks_where(:unsubmitted) == num_tasks
    return 'completed' if num_tasks_where(:completed) == num_tasks
    'in progress'
  end

  def cleanup(destroy_results: false)
    # Delete all associated HITs on Mturk
    Rails.logger.info "Cleaning up MturkBatchJob..."
    tasks.each do |task|
      task.delete_hit
      if destroy_results
        task.results.delete_all
      else
        task.results.update_all({task_id: nil})
      end
    end
  end

  def default_mturk_instructions
    default_instructions_path = File.join(Rails.root, 'app/views/mturk/default_mturk_instructions.md')
    File.read(default_instructions_path) 
  end

  private 

end
