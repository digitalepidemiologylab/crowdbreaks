require 'json'
require 'timeout'

module PipelineApi
  extend ActiveSupport::Concern

  BUCKET_NAME = ENV['S3_BUCKET_NAME']
  STREAM_CONFIG_KEY = 'configs/stream/stream.json'.freeze
  STREAM_STATE_KEY = 'configs/stream/state.json'.freeze
  ECS_CLUSTER = 'crowdbreaks-streamer'.freeze
  ECS_SERVICE_NAME = 'streamer-stg-service-1'.freeze

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

  # pipeline
  def config
    get_s3_object(BUCKET_NAME, STREAM_CONFIG_KEY)
  end

  def status_streamer
    streamer_instances = client.list_container_instances({ cluster: ECS_CLUSTER }).to_h[:container_instance_arns]
    resp = @@ecs_client.describe_container_instances({ cluster: ECS_CLUSTER, container_instances: streamer_instances })
    statuses = []
    resp.to_h[:container_instances].each do |instance|
      statuses << { name: instance[:container_instance_arn].split('/')[-1], status: instance[:status] }
    end
    statuses
  end

  def status_delivery_streams
    stream_names = @@firehose.list_container_instances({ delivery_stream_type: 'DirectPut' }).delivery_stream_names
    statuses = []
    stream_names.each do |stream_name|
      resp = client.describe_delivery_stream({ delivery_stream_name: stream_name })
      status = resp.delivery_stream_description.delivery_stream_status
      statuses << { name: stream_name, status: status }
    end
    statuses
  end

  def stream_activity(**options)
    options = {es_activity_threshold_min: options.fetch(:es_activity_threshold_min, 3000),
               redis_counts_threshold_hours: options.fetch(:redis_counts_threshold_hours, 2)}
    handle_error(error_return_value: {}) do
      resp = self.class.get("/#{PREFIX}/status/stream_activity", query: options)
      resp.parsed_response
    end
  end

  def set_config(data)
    handle_error_notification do
      self.class.post("/#{PREFIX}/config", body: data.to_json, headers: FlaskApi::JSON_HEADER)
    end
  end

  def start_streamer
    # To start streaming, set desired count to 1 and wait until tasks are pending
    _ = @@ecs_client.update_service({ cluster: ECS_CLUSTER, service: ECS_SERVICE_NAME, desiredCount: 1 })
    wait_for_desired_count(ECS_CLUSTER, ECS_SERVICE_NAME, 1)
    @@s3_client.put_object({ body: 'start.json', bucket: BUCKET_NAME, key: STREAM_STATE_KEY })
  end

  def stop_streamer
    # To stop streaming, set desired count to 0 and wait until tasks are stopped
    _ = @@ecs_client.update_service({ cluster: ECS_CLUSTER, service: ECS_SERVICE_NAME, desiredCount: 0 })
    wait_for_desired_count(ECS_CLUSTER, ECS_SERVICE_NAME, 0)
    @@s3_client.put_object({ body: 'stop.json', bucket: BUCKET_NAME, key: STREAM_STATE_KEY })
  end

  def restart_streamer
    stop_streamer
    start_streamer
    @@s3_client.put_object({ body: 'start.json', bucket: BUCKET_NAME, key: STREAM_STATE_KEY })
  end

  private

  def get_s3_object(bucket, key, version_id: nil)
    params = { bucket: bucket, key: key }
    params[:version_id] = version_id if version_id
    JSON.parse(@@s3_client.get_object(params).body.read.force_encoding('UTF-8'))
  end

  def check_if_currently_active(cluster_name, service_name)
    response = @@ecs_client.describe_services({ cluster: cluster_name, services: [service_name] })
    active = true
    name_in_response = false
    response.services.each do |service|
      next unless service.service_name == service_name

      name_in_response = true
      service_count = service.running_count
      service_count += service.pending_count
      active = false if service_count.zero?
    end
    raise ArgumentError "no inquired service name #{service_name} in the response." if name_in_response == false

    Rails.logger.warning('Extra instances were found. Check the ECS.') if service_count > 1
    active
  end

  # def put_hash_to_s3(bucket:, key:, hash:, filename:)
  #   File.open(filename, 'wb') { |file| file.puts JSON.to_json(hash) } unless File.file?(filename)
  #   @@s3_client.put_object({ body: filename, bucket: bucket, key: key })
  # end

  def scan_services(response, service_name, count, time_step, updated, name_in_response)
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
    [updated, name_in_response]
  end

  def wait_for_desired_count(cluster_name, service_name, count, time_step: 30, time_limit: 160)
    updated = false
    Rails.logger.info "#{cluster_name} #{cluster_name}"
    Timeout.timeout(time_limit) do
      until updated
        response = ecs.describe_services({ cluster: cluster_name, services: [service_name] })
        name_in_response = false
        updated, name_in_response = scan_services(response, service_name, count, time_step, updated, name_in_response)
        raise ArgumentError 'no inquired service name in the response.' if name_in_response == false
      end
    end
    Rails.logger.info "ECS service #{service_name} on cluster #{cluster_name} has been updated, " \
                      "desired count = #{service_count}."
  end
end
