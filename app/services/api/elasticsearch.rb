module Elasticsearch
  extend ActiveSupport::Concern
  PREFIX = 'elasticsearch'

  def test_es
    options = {timeout: 5}
    handle_error(error_return_value: false) do
      resp = self.class.get("/#{PREFIX}/test", options)
      resp.parsed_response == 'true'
    end
  end

  def es_stats
    handle_error(error_return_value: {}) do
      resp = self.class.get("/#{PREFIX}/stats")
      resp.parsed_response['indices']
    end
  end

  def es_health
    handle_error(error_return_value: 'error') do
      resp = self.class.get("/#{PREFIX}/health")
      resp.parsed_response['status']
    end
  end

  def create_index(params)
    handle_error_notification do
      self.class.post("/#{PREFIX}/create", body: params.to_json, headers: FlaskApi::JSON_HEADER)
    end
  end
end
