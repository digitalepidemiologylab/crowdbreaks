class MturkBatchJob < ApplicationRecord
  has_many :tasks
  has_many :mturk_tweets
  belongs_to :project

  validates :name, presence: true, uniqueness: {message: "Name must be unique"}
  validates_presence_of :sandbox, :description, :title, :keywords, :lifetime_in_seconds, :assignment_duration_in_seconds, :project, :reward

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
    total_done = num_tasks - (num_tasks_where(:unsubmitted) + num_tasks_where(:submitted))
    (total_done / num_tasks * 100).to_i
  end

  def is_submitted
    status == :submitted or status == :completed ? true : false
  end

  def status
    return 'deleting' if marked_for_deletion
    return 'processing' if processing
    return 'empty' if num_queued_tasks == 0
    return 'unsubmitted' if num_tasks_where(:unsubmitted) == num_tasks
    return 'submitted' if num_tasks_where(:submitted) > 0
    return 'completed' if num_tasks_where(:accepted) == num_tasks
  end

  def cleanup
    # Destroys all associated records
    tasks.destroy_all
    mturk_tweets.each do |t|
      MturkWorker.where(id: t.mturk_workers.pluck(:id)).destroy_all
    end
    mturk_tweets.destroy_all
  end

  def default_mturk_instructions
    default_instructions_path = File.join(Rails.root, 'app/views/mturk/default_mturk_instructions.md')
    File.read(default_instructions_path) 
  end

  private 

end
