class Mturk
  attr_reader :client

  DEFAULT_ACCEPT_MESSAGE = 'Thank you for your work!'
  DEFAULT_REJECT_MESSAGE = 'Your work has been rejected because the majority of questions answered in this task are wrong.'

  def initialize(sandbox: true)
    @client = get_client(sandbox)
  end

  def create_hit_type(batch_job)
    # create a qualification type of this batch (used for dynamic exclusions of workers)
    qual_type_id = generate_exclude_worker_qualification(batch_job.name)
    if qual_type_id.nil?
      ErrorLogger.error "Something went wrong when generating the qualification type. Aborting."
      return
    end
    Rails.logger.info "Generated new qualifaction type ID: #{qual_type_id}"
    # create a HIT type
    props = {
      title: batch_job.title,
      description: batch_job.description,
      reward: batch_job.reward.to_s,
      keywords: batch_job.keywords,
      auto_approval_delay_in_seconds: batch_job.auto_approval_delay_in_seconds,
      assignment_duration_in_seconds: batch_job.assignment_duration_in_seconds,
      qualification_requirements: [
        {
          qualification_type_id: qual_type_id,
          comparator: 'DoesNotExist',   # If worker does not exist on list, worker is qualified
          actions_guarded: "Accept"     # Worker can still preview the task but not accept
        }
      ]
    }
    # system qualfifications (minimum approval rate)
    unless batch_job.minimal_approval_rate.nil?
      qual_props = {
        qualification_type_id: '000000000000000000L0',
        comparator: 'GreaterThanOrEqualTo',
        integer_values: [batch_job.minimal_approval_rate],
        actions_guarded: "Accept"
      }
      props[:qualification_requirements].push(qual_props)
    end
    return @client.create_hit_type(props).hit_type_id, qual_type_id
  end

  def create_hit_with_hit_type(task_id, hit_type_id, batch_job)
    params = {
      hit_type_id: hit_type_id,
      max_assignments: 1,
      lifetime_in_seconds: batch_job.lifetime_in_seconds, 
      question: get_external_question_file,
      requester_annotation: task_id.to_s,
    }
    @client.create_hit_with_hit_type(params).hit
  end

  def check_balance
    @client.get_account_balance
  end

  def list_hits(next_token: nil, max_results: 10)
    _list_hits(next_token, max_results: max_results)
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
        ErrorLogger.error "Cannot delete hit #{hit_id}. HIT needs to be either Assignable, Reviewable or Reviewing."
        return
      end
    end
    handle_error do
      # delete HIT
      @client.delete_hit(hit_id: hit_id)
    end
  end

  # #############################
  # HIT review
  # #############################
  
  def approve_assignment(assignment_id, message: '')
    assignment = get_assignment(assignment_id)
    if assignment.nil?
      ErrorLogger.error "Could not find assignment for assignment Id #{assignment_id}"
      return
    end
    if message.empty?
      message = DEFAULT_ACCEPT_MESSAGE
    end
    handle_error do
      resp = @client.approve_assignment(assignment_id: assignment_id, requester_feedback: message)
      if resp.successful?
        # Put HIT into reviewing state, so it doesn't show up anymore
        update_hit_review_status(assignment.hit.hit_id)
      end
    end
  end

  def update_hit_review_status(hit_id, revert: false)
    handle_error do
      @client.update_hit_review_status(hit_id: hit_id, revert: revert)
    end
  end

  def get_assignment(assignment_id)
    handle_error do
      @client.get_assignment(assignment_id: assignment_id)
    end
  end

  def reject_assignment(assignment_id, message: '')
    if message.empty?
      ErrorLogger.error 'Needs a non-empty rejection message' if message.empty?
      return
    end
    assignment = get_assignment(assignment_id)
    if assignment.nil?
      ErrorLogger.error "Could not find assignment for assignment Id #{assignment_id}"
      return
    end
    handle_error do
      resp = @client.reject_assignment(assignment_id: assignment_id, requester_feedback: message)
    end
    if resp.successful?
      update_hit_review_status(assignment.hit.hit_id)
    end
  end

  def list_reviewable_hits(hit_type_id: nil, next_token: nil, max_results: 30, status: 'Reviewable')
    hits = []
    resp = _list_reviewable_hits(hit_type_id, next_token, max_results, status)
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
      @client.list_assignments_for_hit(hit_id: hit_id)
    end
  end


  # #############################
  # QUALIFICATIONS
  # #############################

  def generate_exclude_worker_qualification(batch_job_name)
    # create a qualification type to exclude workers under certain conditions
    name = "ExcludeWorkersFromBatch_#{batch_job_name}"
    qual_type = find_existing_qualification_type_id(name)
    if not qual_type.nil?
      # delete old type and recreate
      Rails.logger.info "Found old qualification type: #{qual_type}"
      delete_qualification_type(qual_type)
    end
    Rails.logger.info "Creating a new qualification type called '#{name}' to exclude workers..."
    props = {
      name: name,
      description: 'This is a negative qualification which allows to exclude \
      certain workers once they have finished all available work for them.',
      qualification_type_status: "Active",
      auto_granted: true
    }
    handle_error do
      @client.create_qualification_type(props).qualification_type.qualification_type_id
    end
  end

  def delete_qualification_type(qual_type)
    handle_error do
      Rails.logger.info "Deleting qualification type #{qual_type}..."
      # Note: Sometimes this seems to throw an error when executing a short time befor or after the creation of the same qual type
      # From the docs: It may take up to 48 hours before DeleteQualificationType completes and the unique name of 
      # the Qualification type is available for reuse with CreateQualificationType.
      @client.delete_qualification_type(qualification_type_id: qual_type)
    end
  end

  def find_existing_qualification_type_id(name)
    handle_error do
      qual_types = @client.list_qualification_types(query: name, must_be_requestable: true, must_be_owned_by_caller: true)
      Rails.logger.debug "Found #{qual_types.num_results} for search of qualification types"
      if qual_types.num_results > 0
        return qual_types.qualification_types.first.qualification_type_id
      else
        nil
      end
    end
  end

  def exclude_worker_from_qualification(worker_id, qualification_type_id)
    handle_error do
      @client.associate_qualification_with_worker({
        qualification_type_id: qualification_type_id,
        worker_id: worker_id
      })
    end
  end


  private

  def _list_hits(next_token, max_results: 10)
    handle_error(error_return_value: {'hits': [], 'next_token': '', num_results: 0}) do
      @client.list_hits(next_token: next_token, max_results: max_results)
    end
  end

  def _list_reviewable_hits(hit_type_id, next_token, max_results, status)
    handle_error(error_return_value: {'hits': [], 'next_token': '', num_results: 0}) do
      @client.list_reviewable_hits(hit_type_id: hit_type_id, next_token: next_token, max_results: max_results, status: status)
    end
  end

  def handle_error(error_return_value: nil)
    begin
      yield
    rescue StandardError => e
      if error_return_value.is_a?(Hash)
        # convert to Hashie Mash to behave similar to a response object
        return Hashie::Mash.new(error_return_value)
      end
      error_return_value
    end
  end

  def get_client(sandbox)
    if sandbox
      Aws::MTurk::Client.new(endpoint: 'https://mturk-requester-sandbox.us-east-1.amazonaws.com', region: 'us-east-1')
    else
      Aws::MTurk::Client.new(endpoint: 'https://mturk-requester.us-east-1.amazonaws.com', region: 'us-east-1')
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
