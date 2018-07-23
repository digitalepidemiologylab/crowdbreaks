class MturkBatchJob < ApplicationRecord
  has_many :tasks, dependent: :destroy
  belongs_to :project

  validates :name, presence: true, uniqueness: {message: "Name must be unique"}
  validates_presence_of :sandbox, :description, :title, :keywords, :lifetime_in_seconds, :assignment_duration_in_seconds, :project, :reward

  attr_accessor :job_file
  attr_accessor :number_of_assignments

  def mturk_init
    # Set up Mturk for submitting new jobs
    host = sandbox ? :Sandbox : :Production
    requester = Amazon::WebServices::MechanicalTurkRequester.new(
      Host: host,
      AWSAccessKeyId: ENV['AWS_ACCESS_KEY_ID'],
      AWSAccessKey: ENV['AWS_SECRET_ACCESS_KEY'])

    if ENV['ENVIRONMENT_NAME'] == 'production'
      question_file_path = File.join(Rails.root, 'app/views/mturk/external_question.xml')
    else
      question_file_path = File.join(Rails.root, 'app/views/mturk/external_question_staging.xml')
    end

    question_file = File.read(question_file_path) 
    props = {
        Title: title,
        Description: description,
        MaxAssignments: 1,
        Reward: {
          Amount: reward.to_s,
          CurrencyCode: 'USD'
        },
        Keywords: keywords,
        LifetimeInSeconds: lifetime_in_seconds,
        Question: question_file,
        AutoApprovalDelayInSeconds: auto_approval_delay_in_seconds
    }
    return requester, props
  end

  def num_tasks
    tasks.count
  end

  def num_tasks_completed
    tasks.where.not(lifecycle_status: :unsubmitted).count
  end

  def status
    return :unsubmitted if num_tasks_completed == 0
    num_tasks_completed == num_tasks ? :completed : :submitted
  end

  def default_mturk_instructions
    default_instructions_path = File.join(Rails.root, 'app/views/mturk/default_mturk_instructions.md')
    File.read(default_instructions_path) 
  end

  private 

end
