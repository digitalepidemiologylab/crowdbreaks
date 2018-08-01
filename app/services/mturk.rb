class Mturk
  attr_reader :client
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

  def list_hits(next_token: nil)
    hits = []
    resp = _list_hits(next_token)
    resp.hits.each do |hit|
      hits.push({
        hit_id: hit.hit_id,
        hit_type_id: hit.hit_type_id,
        title: hit.title,
        status: hit.hit_status,
        review_status: hit.hit_review_status,
      })
    end
    return {'hits': hits, 'next_token': resp.next_token, 'num_results': resp.num_results}
  end

  def get_hit(hit_id)
    handle_error do
      resp = @client.get_hit(hit_id: hit_id)
      p resp.hit
      resp.hit
    end
  end

  def delete_hit(hit_id)
    handle_error do
      # For HITS in 'Assignable' state forcefully expire by setting expiration time in the past
      @client.update_expiration_for_hit({hit_id: hit_id, expire_at: 1.day.ago})

      # delete HIT
      @client.delete_hit(hit_id: hit_id)
    end
  end

  private

  def _list_hits(next_token)
    handle_error(error_return_value: {'hits': [], 'next_token': '', num_results: 0}) do
      @client.list_hits(next_token: next_token, max_results: 10)
    end
  end

  def handle_error(error_return_value: nil)
    begin
      yield
    rescue StandardError => e
      RorVsWild.record_error(e)
      if error_return_value.is_a?(Hash)
        # convert to Hashie Mash to behave similar to a response object
        return Hashie::Mash.new(error_return_value)
      end
      error_return_value
    end
  end

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
