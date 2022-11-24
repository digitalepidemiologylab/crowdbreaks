require 'json'
require 'timeout'

module PipelineApi
  extend ActiveSupport::Concern

  AWS_SERVICE_ERROR = Aws::Errors::ServiceError
  BUCKET_NAME = ENV['S3_BUCKET_NAME']
  STREAM_CONFIG_KEY = 'configs/stream/stream.json'.freeze
  STREAM_STATE_KEY = 'configs/stream/state.json'.freeze
  SAMPLES_STATUS_KEY = 'other/csv/automatic-samples/status.json'.freeze
  # PRIMARY_JOBS_KEY = 'other/csv/automatic-samples/primary_jobs.json'.freeze
  SAMPLES_STATUS_PATH = 'app/services/api/sampled_status.json'.freeze
  ECS_CLUSTER_NAME = ENV['ECS_CLUSTER_NAME']
  ECS_SERVICE_NAME = ENV['ECS_SERVICE_NAME']
  GROUP_NAME = 'Crowdbreaks'.freeze

  @@s3_client = Aws::S3::Client.new(
    region: Aws.config[:region],
    access_key_id: Aws.config[:credentials].access_key_id,
    secret_access_key: Aws.config[:credentials].secret_access_key
  )

  @@ecs_client = Aws::ECS::Client.new(
    region: Aws.config[:region],
    access_key_id: Aws.config[:credentials].access_key_id,
    secret_access_key: Aws.config[:credentials].secret_access_key
  )

  @@firehose = Aws::Firehose::Client.new(
    region: Aws.config[:region],
    access_key_id: Aws.config[:credentials].access_key_id,
    secret_access_key: Aws.config[:credentials].secret_access_key
  )

  @@eventbridge = Aws::EventBridge::Client.new(
    region: Aws.config[:region],
    access_key_id: Aws.config[:credentials].access_key_id,
    secret_access_key: Aws.config[:credentials].secret_access_key
  )

  @@resourcegroups = Aws::ResourceGroups::Client.new(
    region: Aws.config[:region],
    access_key_id: Aws.config[:credentials].access_key_id,
    secret_access_key: Aws.config[:credentials].secret_access_key
  )

  def check_subsamples_status(project_name)
    latest_use = LocalBatchJob.where(auto: true).last.created_at
    prefix = "other/csv/mturk-batch-job-results/project_#{project_name}/evaluate_ids"
    response = nil
    Helpers::ErrorHandler.handle_error(
      AWS_SERVICE_ERROR, occured_when: "Checking subsamples status for project #{project_name}"
    ) do
      response = @@s3_client.list_objects_v2({ bucket: BUCKET_NAME, prefix: prefix })
    end

    s3_objs = response.contents.map do |obj|
      datetime = DateTime.parse(obj.key.split('/')[-1].split('-')[1]) # evaluate_ids-<_datetime_>-<type>-<batch_name>-...
      mturk_batch_name = obj.key.split('/')[-1].split('-')[3] # evaluate_ids-<datetime>-<type>-<_batch_name_>-...
      if datetime > latest_use # Only include S3 files that haven't been processed
        tweets = get_s3_object(BUCKET_NAME, s3_key).read
        { subsample_s3_key: obj.key, job_file: tweets, mturk_batch_name: mturk_batch_name }
      end
    end
    s3_objs = s3_objs.sort_by! { |k| k[:created_at] }

    if s3_objs.length.zero?
      return Helpers::ApiResponse.new(
        status: :error, message: "Evaluation files not found for project '#{project_name}'."
      )
    end

    Helpers::ApiResponse.new(status: :success, body: s3_objs)
  end

  # def upload_primary_jobs(primary_jobs)
  #   Helpers::ErrorHandler.handle_error(AWS_SERVICE_ERROR, occured_when: 'uploading primary jobs to S3') do
  #     put_data_to_s3(bucket: BUCKET_NAME, key: PRIMARY_JOBS_KEY, data: primary_jobs, filename: 'app/services/api/primary_jobs.json')
  #     Helpers::ApiResponse.new(status: :success, message: 'Successfully uploaded primary jobs to S3.')
  #   end
  # end

  # def load_primary_jobs
  #   Helpers::ErrorHandler.handle_error(AWS_SERVICE_ERROR, occured_when: 'loading primary jobs') do
  #     Helpers::ApiResponse.new(status: :success, body: get_s3_json(BUCKET_NAME, PRIMARY_JOBS_KEY))
  #   end
  # end

  def load_new_batch_cron(name)
    Helpers::ErrorHandler.handle_error(AWS_SERVICE_ERROR, occured_when: "describing the EventBridge rule '#{name}'") do
      Helpers::ApiResponse.new(status: :success, body: @@eventbridge.describe_rule({ name: name }).schedule_expression)
    end
  end

  def check_samples_status(project_name)
    latest_use = MturkBatchJob.where(auto: true).last.created_at
    prefix = "other/csv/automatic-samples/project_#{project_name}/auto_sample-no_text"
    response = nil
    Helpers::ErrorHandler.handle_error(
      AWS_SERVICE_ERROR, occured_when: "Checking samples status for project #{project_name}"
    ) do
      response = @@s3_client.list_objects_v2({ bucket: BUCKET_NAME, prefix: prefix })
    end

    s3_objs = response.contents.map do |obj|
      datetime = DateTime.parse(obj.key.split('/')[-1].split('-')[1]) # auto_sample-no_text-<project_name>-<_datetime_>-...
      if datetime > latest_use # Only include S3 files that haven't been processed
        tweets = get_s3_object(BUCKET_NAME, s3_key).read
        { sample_s3_key: obj.key, job_file: tweets }
      end
    end
    s3_objs = s3_objs.sort_by! { |k| k[:created_at] }

    if s3_objs.length.zero?
      return Helpers::ApiResponse.new(
        status: :error, message: "Sample files not found for project '#{project_name}'."
      )
    end

    Helpers::ApiResponse.new(status: :success, body: s3_objs)
  end

  # List group resources
  def list_group_resources(resources_hash: {}, next_token: nil)
    Helpers::ErrorHandler.handle_error(AWS_SERVICE_ERROR, occured_when: "listing #{GROUP_NAME} resources") do
      response = @@resourcegroups.list_group_resources({ group: GROUP_NAME, max_results: 50, next_token: next_token })
      response.resources.each do |r|
        if resources_hash.fetch(r.identifier.resource_type, nil).nil?
          resources_hash[r.identifier.resource_type] = [r]
        else
          resources_hash[r.identifier.resource_type] << r
        end
      end
      unless response.next_token.blank?
        list_group_resources(resources_hash: resources_hash, next_token: response.next_token)
      end
      Helpers::ApiResponse.new(status: :success, body: resources_hash.sort.to_h)
    end
  end

  # Create-update an event
  def create_update_cron_event(name:, cron:)
    Helpers::ErrorHandler.handle_error(
      AWS_SERVICE_ERROR, occured_when: "updating the EventBridge rule '#{name}' with the cron '#{cron}'"
    ) do
      response = @@eventbridge.put_rule(
        { name: name, schedule_expression: cron, state: 'ENABLED',
          tags: [{ key: 'project', value: 'crowdbreaks' }] }
      )
      Helpers::ApiResponse.new(status: :success, message: 'Successfully updated the rule.', body: response.rule_arn)
    end
  end

  # Pipeline
  def config
    Helpers::ErrorHandler.handle_error(AWS_SERVICE_ERROR, occured_when: 'downloading the config from S3') do
      Helpers::ApiResponse.new(status: :success, body: get_s3_json(BUCKET_NAME, STREAM_CONFIG_KEY))
    end
  end

  def check_state
    state = nil
    Helpers::ErrorHandler.handle_error(AWS_SERVICE_ERROR, occured_when: 'downloading the config from S3') do
      state = get_s3_json(BUCKET_NAME, STREAM_STATE_KEY)['state']
    end
    ecs_state = status_streaming.success? ? { running: true, paused: false }[status_streaming.body] : nil
    Helpers::ApiResponse.new(status: :success, body: state == ecs_state)
  end

  def status_streaming
    Helpers::ErrorHandler.handle_error(AWS_SERVICE_ERROR, occured_when: 'checking whether ECS container is running') do
      Helpers::ApiResponse.new(status: :success, body: check_if_currently_active(ECS_CLUSTER_NAME, ECS_SERVICE_NAME))
    end
  end

  def status_streamer
    Helpers::ErrorHandler.handle_error(AWS_SERVICE_ERROR, occured_when: 'fetching the streamer status from ECS') do
      # clusters = @@ecs_client.list_clusters({})
      # description = @@ecs_client.describe_clusters({ clusters: ['crowdbreaks-streamer'] })
      # puts clusters
      # puts description
      tasks = @@ecs_client.list_tasks({ cluster: ECS_CLUSTER_NAME, service_name: ECS_SERVICE_NAME }).task_arns
      statuses = []
      unless tasks.empty?
        resp = @@ecs_client.describe_tasks({ tasks: tasks })
        resp.tasks.each do |task|
          task.containers.each do |container|
            statuses << { name: container.container_arn.split('/')[-1], status: container.last_status }
          end
        end
      end
      Helpers::ApiResponse.new(status: :success, body: statuses)
    end
  end

  def status_delivery_streams
    Helpers::ErrorHandler.handle_error(
      AWS_SERVICE_ERROR, occured_when: 'fetching Firehose delivery stream statuses'
    ) do
      stream_names = @@firehose.list_delivery_streams({ delivery_stream_type: 'DirectPut' }).delivery_stream_names
      statuses = []
      stream_names.each do |stream_name|
        resp = @@firehose.describe_delivery_stream({ delivery_stream_name: stream_name })
        status = resp.delivery_stream_description.delivery_stream_status
        statuses << { name: stream_name, status: status }
      end
      Helpers::ApiResponse.new(status: :success, body: statuses)
    end
  end

  def upload_config(config)
    Helpers::ErrorHandler.handle_error(AWS_SERVICE_ERROR, occured_when: 'uploading the config to S3') do
      put_data_to_s3(bucket: BUCKET_NAME, key: STREAM_CONFIG_KEY, data: config, filename: 'app/services/api/stream.json')
      Helpers::ApiResponse.new(status: :success, message: 'Successfully uploaded the config to S3.')
    end
  end

  def start_streamer
    # To start streaming, set desired count to 1 and wait until tasks are pending
    Helpers::ErrorHandler.handle_error(AWS_SERVICE_ERROR, occured_when: 'starting streamer') do
      _ = @@ecs_client.update_service({ cluster: ECS_CLUSTER_NAME, service: ECS_SERVICE_NAME, desired_count: 1 })
      wait_for_desired_count(ECS_CLUSTER_NAME, ECS_SERVICE_NAME, 1)
    end
    Helpers::ErrorHandler.handle_error(AWS_SERVICE_ERROR, occured_when: 'updating the streamer state on S3') do
      File.open('app/services/api/start.json', 'rb') do |file|
        @@s3_client.put_object({ body: file, bucket: BUCKET_NAME, key: STREAM_STATE_KEY })
      end
    end
    Helpers::ApiResponse.new(status: :success, message: 'Successfully started streamer.')
  end

  def stop_streamer
    # To stop streaming, set desired count to 0 and wait until tasks are stopped
    Helpers::ErrorHandler.handle_error(AWS_SERVICE_ERROR, occured_when: 'stopping streamer') do
      _ = @@ecs_client.update_service({ cluster: ECS_CLUSTER_NAME, service: ECS_SERVICE_NAME, desired_count: 0 })
      wait_for_desired_count(ECS_CLUSTER_NAME, ECS_SERVICE_NAME, 0)
    end
    Helpers::ErrorHandler.handle_error(AWS_SERVICE_ERROR, occured_when: 'updating the streamer state on S3') do
      File.open('app/services/api/stop.json', 'rb') do |file|
        @@s3_client.put_object({ body: file, bucket: BUCKET_NAME, key: STREAM_STATE_KEY })
      end
    end
    Helpers::ApiResponse.new(status: :success, message: 'Successfully stopped streamer.')
  end

  def restart_streamer
    resp_stop = stop_streamer
    return resp_stop unless resp_stop.success?

    resp_start = start_streamer
    return resp_start unless resp_start.success?

    Helpers::ErrorHandler.handle_error(AWS_SERVICE_ERROR, occured_when: 'updating the streamer state on S3') do
      File.open('app/services/api/start.json', 'rb') do |file|
        @@s3_client.put_object({ body: file, bucket: BUCKET_NAME, key: STREAM_STATE_KEY })
      end
    end
    Helpers::ApiResponse.new(status: :success, message: 'Successfully restarted streamer.')
  end

  private

  def get_s3_object(bucket, key, version_id: nil)
    params = { bucket: bucket, key: key }
    params[:version_id] = version_id if version_id
    @@s3_client.get_object(params).body
  end

  def get_s3_json(bucket, key, version_id: nil)
    JSON.parse get_s3_object(bucket, key, version_id: version_id).read.force_encoding('UTF-8')
  end

  def check_if_currently_active(cluster_name, service_name)
    response = @@ecs_client.describe_services({ cluster: cluster_name, services: [service_name] })
    active = true
    name_in_response = false
    running_count = 0
    pending_count = 0
    response.services.each do |service|
      next unless service.service_name == service_name

      name_in_response = true
      running_count = service.running_count
      pending_count = service.pending_count
      active = false if (running_count + pending_count).zero?
    end
    raise ArgumentError "no inquired service name #{service_name} in the response." if name_in_response == false

    Rails.logger.info('Extra instances were found. Check the ECS.') if running_count > 1
    active ? :running : :paused
  end

  def put_data_to_s3(bucket:, key:, data:, filename:)
    File.open(filename, 'w+b') do |file|
      file.puts data
      @@s3_client.put_object({ body: file, bucket: bucket, key: key })
    end
  end

  def scan_services(response, service_name, count, time_step, updated, name_in_response)
    service_count = 0
    response.services.each do |service|
      next unless service.service_name == service_name

      name_in_response = true
      service_count = service.running_count
      service_count += service.pending_count
      if service_count != count
        Rails.logger.info "Running/pending count: #{service_count}, desired: #{service_count}."
        sleep(time_step)
      else
        updated = true
      end
    end
    [updated, name_in_response, service_count]
  end

  def wait_for_desired_count(cluster_name, service_name, count, time_step: 30, time_limit: 160)
    updated = false
    Rails.logger.info "#{cluster_name} #{cluster_name}"
    service_count = 0
    Timeout.timeout(time_limit) do
      until updated
        response = @@ecs_client.describe_services({ cluster: cluster_name, services: [service_name] })
        name_in_response = false
        updated, name_in_response, service_count = scan_services(response, service_name, count, time_step, updated, name_in_response)
        raise ArgumentError 'no inquired service name in the response.' if name_in_response == false
      end
    end
    Rails.logger.info "ECS service #{service_name} on cluster #{cluster_name} has been updated, " \
                      "desired count = #{service_count}."
  end
end
