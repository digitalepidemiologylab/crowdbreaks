class Mturk
  attr_reader :client

  DEFAULT_ACCEPT_MESSAGE = 'Thank you for your work!'
  DEFAULT_REJECT_MESSAGE = ''

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
      resp.hit
    end
  end

  def delete_hit(hit_id)
    hit = get_hit(hit_id)
    unless hit.nil?
      case hit.hit_status
      when 'Assignable'
        # For HITS in 'Assignable' state forcefully expire by setting expiration time in the past
        @client.update_expiration_for_hit({hit_id: hit_id, expire_at: 1.day.ago})
      when 'Reviewable', 'Reviewing'
        @client.update_expiration_for_hit({hit_id: hit_id, expire_at: 1.day.ago})
        Rails.logger.info "Attempt to delete hit #{hit_id}..."
      else
        Rails.logger.error "Cannot delete hit #{hit_id}. HIT needs to be either Assignable, Reviewable or Reviewing"
        return
      end
    end
    handle_error do
      # delete HIT
      @client.delete_hit(hit_id: hit_id)
    end
  end

  def approve_assignment(assignment_id, message: '')
    assignment = get_assignment(assignment_id)
    if assignment.nil?
      Rails.logger.error "Could not find assignment for assignment Id #{assignment_id}"
      return
    end
    if message.empty?
      message = DEFAULT_ACCEPT_MESSAGE
    end
    handle_error do
      @client.approve_assignment(assignment_id: assignment_id, requester_feedback: message)
    end
  end

  def get_assignment(assignment_id)
    handle_error do
      @client.get_assignment(assignment_id: assignment_id)
    end
  end

  def reject_assignment(assignment_id, message: '')
    if message.empty?
      Rails.logger.error 'Needs a non-empty rejection message' if message.empty?
      return
    end
    handle_error do
      @client.reject_assignment(assignment_id: assignment_id, requester_feedback: message)
    end
  end

  def list_reviewable_hits(hit_type_id: nil, next_token: nil, max_results: 30)
    hits = []
    resp = _list_reviewable_hits(hit_type_id, next_token, max_results)
    resp.hits.each do |hit|
      list_assignments = list_assignments_for_hit(hit.hit_id)
      if list_assignments.assignments.empty?
        hits.push({
          hit_id: hit.hit_id,
        })
      else
        hits.push({
          hit_id: hit.hit_id,
          assignment_id: list_assignments.assignments[0].assignment_id,
          worer_id: list_assignments.assignments[0].worker_id,
          accept_time: list_assignments.assignments[0].accept_time,
          submit_time: list_assignments.assignments[0].submit_time,
          approval_time: list_assignments.assignments[0].approval_time,
          rejection_time: list_assignments.assignments[0].rejection_time,
          assignment_status: list_assignments.assignments[0].assignment_status,
        })
      end
    end
    return {'hits': hits, 'next_token': resp.next_token, 'num_results': resp.num_results}
  end


  def list_assignments_for_hit(hit_id)
    handle_error(error_return_value: {'assignments': [], num_results: 0}) do
      # By default max_assignments is set to 1, therefore we only expect 1 result
      @client.list_assignments_for_hit(hit_id: hit_id, max_results: 1)
    end
  end


  private

  def _list_hits(next_token)
    handle_error(error_return_value: {'hits': [], 'next_token': '', num_results: 0}) do
      @client.list_hits(next_token: next_token, max_results: 10)
    end
  end

  def _list_reviewable_hits(hit_type_id, next_token, max_results)
    handle_error(error_return_value: {'hits': [], 'next_token': '', num_results: 0}) do
      @client.list_reviewable_hits(hit_type_id: hit_type_id, next_token: next_token, max_results: max_results)
    end
  end

  def handle_error(error_return_value: nil)
    begin
      yield
    rescue StandardError => e
      RorVsWild.record_error(e)
      p e
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
