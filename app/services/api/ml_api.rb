require 'json'

module MlApi
  extend ActiveSupport::Concern

  AWS_SERVICE_ERROR = Aws::Errors::ServiceError

  @@sagemaker = Aws::SageMaker::Client.new(
    region: Aws.config[:region],
    access_key_id: Aws.config[:credentials].access_key_id,
    secret_access_key: Aws.config[:credentials].secret_access_key
  )

  @@sagemaker_runtime = Aws::SageMakerRuntime::Client.new(
    region: Aws.config[:region],
    access_key_id: Aws.config[:credentials].access_key_id,
    secret_access_key: Aws.config[:credentials].secret_access_key
  )

  def create_endpoint(model_name)
    Helpers::ErrorHandler.handle_error(AWS_SERVICE_ERROR, occured_when: 'creating a Sagemaker endpoint') do
      @@sagemaker.create_endpoint({ endpoint_name: model_name })
      Helpers::ApiResponse.new(status: :success)
    end
  end

  def delete_endpoint(model_name)
    Helpers::ErrorHandler.handle_error(AWS_SERVICE_ERROR, occured_when: 'deleting a Sagemaker endpoint') do
      @@sagemaker.delete_endpoint({ endpoint_name: model_name })
      Helpers::ApiResponse.new(status: :success)
    end
  end

  def delete_model(model_name)
    Helpers::ErrorHandler.handle_error(AWS_SERVICE_ERROR, occured_when: 'deleting a Sagemaker model') do
      @@sagemaker.delete_model({ model_name: model_name })
      Helpers::ApiResponse.new(status: :success)
    end
  end

  def endpoint_labels(model_name, use_cache: true)
    cached("endpoint_labels-#{model_name}", use_cache: use_cache) do
      response = predict(endpoint_name: model_name)
      labels = JSON.parse(response.body)['predictions'][0]['labels_fixed']
      label_vals = labels_to_int(labels)
      if label_vals.nil?
        return Helpers::ApiResponse.new(status: :fail, message: 'Did not manage to get the endpoint labels.')
      end

      Helpers::ApiResponse.new(status: :success, body: { labels: labels, label_vals: label_vals })
    end
  end

  def list_model_endpoints(use_cache: true)
    cached('list_model_endpoints_response', use_cache: use_cache) do
      avoid_duplicate_requests('list_model_endpoints_response') do
        models = nil
        endpoints = nil
        Helpers::ErrorHandler.handle_error(AWS_SERVICE_ERROR, occured_when: 'listing Sagemaker models') do
          models = @@sagemaker.list_models({}).models
        end
        Helpers::ErrorHandler.handle_error(AWS_SERVICE_ERROR, occured_when: 'listing Sagemaker endpoints') do
          endpoints = @@sagemaker.list_endpoints({}).endpoints
        end
        endpoints = endpoints.map { |e| { e.endpoint_name => [e.endpoint_arn, e.endpoint_status] } }.reduce Hash.new, :merge
        model_endpoints = get_model_endpoints(models, endpoints)
        Helpers::ApiResponse.new(status: :success, body: model_endpoints)
      end
    end
  end

  def predict(text: '', endpoint_name: '')
    Helpers::ErrorHandler.handle_error(AWS_SERVICE_ERROR, occured_when: 'invoking a Sagemaker endpoint') do
      response = @@sagemaker_runtime.invoke_endpoint(
        endpoint_name: endpoint_name,
        body: { text: text }.to_json,
        content_type: 'application/json'
      )
      Helpers::ApiResponse.new(status: :success, body: response.body.read)
    end
  end

  private

  def get_model_endpoints(models, endpoints)
    model_endpoints = []
    models.each do |model|
      model_endpoint = { **model.to_h, endpoint_arn: '' }
      # model_endpoint[:project_name] = model.project_name.start_with?('project_') ? model.project_name[8..-1] : model.project_name
      begin
        tags = @@sagemaker.list_tags({ resource_arn: model.model_arn }).tags.map(&:to_h)
        model_endpoint[:tags] = tags.map { |tag| { tag[:key].to_sym => tag[:value] } }.reduce Hash.new, :merge
      rescue AWS_SERVICE_ERROR
        model_endpoint[:tags] = []
      end
      if endpoints.keys.include? model.model_name
        model_endpoint[:has_endpoint] = true
        model_endpoint[:endpoint_arn] = endpoints[model.model_name][0]
        model_endpoint[:endpoint_status] = endpoints[model.model_name][1]
      end
      model_endpoints << model_endpoint
    end
    model_endpoints
  end

  def labels_to_int(labels)
    # Heuristic to convert label to numeric value. Parses leading numbers in label tags such as 1_worried -> 1.
    # If any conversion fails this function will return `nil`
    # (from the old streamer Python app)
    label_vals = []
    labels.each do |label|
      case label
      when 'positive'
        label_vals << 1
      when 'negative'
        label_vals << -1
      when 'neutral'
        label_vals << 0
      else
        label_split = label.split('_')
        begin
          label_val = Integer(label_split[0])
        rescue ArgumentError
          return nil
        else
          label_vals.append(label_val)
        end
      end
    end
    label_vals
  end
end
