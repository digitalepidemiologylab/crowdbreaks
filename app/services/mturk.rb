class Mturk
  def initialize(sandbox: true)
    @client = get_client(sandbox)
  end

  def create_hit_type(batch_job)
    # create a new hit type given a Mturk Batch Job object
    props = {
      title: batch_job.title,
      description: batch_job.description,
      reward: batch_job.reward.to_s,
      keywords: batch_job.keywords,
      auto_approval_delay_in_seconds: batch_job.auto_approval_delay_in_seconds,
      assignment_duration_in_seconds: batch_job.assignment_duration_in_seconds
    }
    @client.create_hit_type(props).hit_type_id
  end

  def create_hit_with_hit_type(task_id, hit_type_id, batch_job)
    params = {
      hit_type_id: hit_type_id,
      max_assignments: 1,
      lifetime_in_seconds: batch_job.lifetime_in_seconds, 
      question: get_external_question_file,
      requester_annotation: task_id.to_s
    }
    @client.create_hit_with_hit_type(params).hit
  end

  def check_balance
    @client.get_account_balance
  end


  private

  def get_client(sandbox)
    if sandbox
      Aws::MTurk::Client.new(endpoint: 'https://mturk-requester-sandbox.us-east-1.amazonaws.com')
    else
      Aws::MTurk::Client.new(endpoint: 'https://mturk-requester.us-east-1.amazonaws.com')
    end
  end

  def get_external_question_file
    if ENV['ENVIRONMENT_NAME'] == 'production'
      question_file_path = File.join(Rails.root, 'app/views/mturk/external_question.xml')
    else
      question_file_path = File.join(Rails.root, 'app/views/mturk/external_question_staging.xml')
    end
    File.read(question_file_path) 
  end
end
