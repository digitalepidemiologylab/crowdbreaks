class MturkBatchJob < ApplicationRecord
  include ActiveModel::Validations

  has_many :tasks, dependent: :delete_all
  has_many :mturk_tweets, dependent: :delete_all
  belongs_to :project

  validates :name, presence: true, uniqueness: {message: "Name must be unique"}
  validates_presence_of :sandbox, :description, :title, :keywords, :lifetime_in_seconds, :assignment_duration_in_seconds, :project, :reward
  validate :number_of_assignments_range
  validates_with CsvValidator, fields: [:job_file]


  attr_accessor :job_file

  def number_of_assignments_range
    if number_of_assignments.present?
      if number_of_assignments.to_i == 0 or number_of_assignments.to_i > 100
        errors.add(:number_of_assignments, 'Number assignments cannot be 0 or >100')
      end
    end
  end

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
    total_done = num_tasks - num_tasks_where(:completed)
    return 0 if total_done == 0
    (total_done / num_tasks * 100).to_i
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
