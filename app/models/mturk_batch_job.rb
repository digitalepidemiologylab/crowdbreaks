class MturkBatchJob < ApplicationRecord
  has_many :tasks, dependent: :destroy
  belongs_to :project

  validates :name, presence: true, uniqueness: {message: "Name must be unique"}
  validates :job_file, presence: true
  validates :project, presence: true

  attr_accessor :job_file
  attr_accessor :number_of_assignments

  enum status: [:unsubmitted, :submitted, :completed]
  STATUS_LABELS = {
    unsubmitted: 'label-default',
    submitted: 'label-primary',
    completed: 'label-success'
  }

  def mturk_init
    # Set up Mturk for submitting new jobs
    host = sandbox ? :Sandbox : :Production
    requester = Amazon::WebServices::MechanicalTurkRequester.new(
      Host: host,
      AWSAccessKeyId: ENV['AWS_ACCESS_KEY_ID'],
      AWSAccessKey: ENV['AWS_SECRET_ACCESS_KEY'])
    title = 'Crowdbreaks'
    desc = 'Answer a sequence of questions about a tweet'
    keywords = 'twitter, science, sentiment, vaccinations'
    reward = 0.03
    question_file_path = File.join(Rails.root, 'app/views/mturk/external_question.xml')
    question_file = File.read(question_file_path) 
    props = {
        Title: title,
        Description: desc,
        MaxAssignments: 1,
        Reward: {
          Amount: reward,
          CurrencyCode: 'USD'
        },
        Keywords: keywords,
        LifetimeInSeconds: 60 * 60 * 24 * 1,
        Question: question_file,
        AutoApprovalDelayInSeconds: 3600
    }
    return requester, props
  end

  private 

end
