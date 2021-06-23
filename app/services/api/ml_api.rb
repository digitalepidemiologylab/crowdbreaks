module MlApi
  extend ActiveSupport::Concern
  PREFIX = 'ml'
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

  def predict(text: '', endpoint_name: '')
    Helpers::ErrorHandler.handle_error(AWS_SERVICE_ERROR, occured_when: 'invoking a Sagemaker endpoint') do
      response = @@sagemaker_runtime.invoke_endpoint(
        endpoint_name: endpoint_name,
        body: { text: text },
        content_type: 'application/json'
      )
      Helpers::ApiResponse.new(status: :success, body: response.body)
    end
  end

  def list_model_endpoints(use_cache: true)
    models = @@sagemaker.list_models({}).models
    model_endpoints = []
    endpoints = @@sagemaker.list_endpoints({}).endpoints
    endpoints = endpoints.map { { e.endpoint_name => [e.endpoint_arn, e.endpoint_status] } }.reduce Hash.new, :merge
    models.each do |model|
      model_endpoint = { model_name: model.model_name, endpoint_arn: '' }
      model_endpoint[:tags] = @@sagemaker.list_tags({}).tags
      if endpoints.keys.include? model.model_name
        model_endpoint[:has_endpoint] = true
        model_endpoint[:endpoint_arn] = endpoints[model.model_name][0]
        model_endpoint[:endpoint_status] = endpoints[model.model_name][1]
      end
      model_endpoints << model_endpoint
    end
    model_endpoints
  end

  def endpoint_labels(model_name, use_cache: true)
    cache_key = "endpoint_labels-#{model_name}"
    cached(cache_key, use_cache=use_cache, cache_duration=1.hour) do
      data = {'model_endpoint': model_name}
      resp = self.class.post("/#{PREFIX}/endpoint_labels", body: data.to_json, headers: FlaskApi::JSON_HEADER)
      resp.parsed_response
    end
  end


  def delete_model(model_name)
    data = {'model_name': model_name}
    self.class.post("/#{PREFIX}/delete_model", body: data.to_json, headers: FlaskApi::JSON_HEADER)
  end

  def create_endpoint(model_name)
    data = {'model_name': model_name}
    self.class.post("/#{PREFIX}/create_endpoint", body: data.to_json, headers: FlaskApi::JSON_HEADER)
  end

  def delete_endpoint(model_name)
    data = {'model_name': model_name}
    self.class.post("/#{PREFIX}/delete_endpoint", body: data.to_json, headers: FlaskApi::JSON_HEADER)
  end

  private

  def avoid_duplicate_requests(cache_key)
    return if Rails.cache.exist?(cache_key)
    Rails.cache.write(cache_key, 1, expires_in: 1.seconds)
    yield
  end
end
