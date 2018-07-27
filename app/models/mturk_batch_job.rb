class MturkBatchJob < ApplicationRecord
  has_many :tasks
  belongs_to :project

  validates :name, presence: true, uniqueness: {message: "Name must be unique"}
  validates_presence_of :sandbox, :description, :title, :keywords, :lifetime_in_seconds, :assignment_duration_in_seconds, :project, :reward

  attr_accessor :job_file
  attr_accessor :number_of_assignments

  def num_tasks
    tasks.count
  end

  def num_tasks_where(status)
    tasks.where(lifecycle_status: status).count
  end

  def status
    return 'empty' if num_tasks == 0
    return 'completed' if num_tasks_where(:accepted) == num_tasks
    return num_tasks_where(:submitted) > 0 ? 'processing' : 'unsubmitted'
  end

  def default_mturk_instructions
    default_instructions_path = File.join(Rails.root, 'app/views/mturk/default_mturk_instructions.md')
    File.read(default_instructions_path) 
  end

  private 

end
