module Ml
  extend ActiveSupport::Concern
  PREFIX = 'ml'

  def list_endpoints
    handle_error(error_return_value: []) do
      self.class.get("/#{PREFIX}/list_endpoints")
    end
  end

  def list_models
    handle_error(error_return_value: []) do
      self.class.get("/#{PREFIX}/list_models")
    end
  end

  def list_model_endpoints
    handle_error(error_return_value: []) do
      self.class.get("/#{PREFIX}/list_model_endpoints")
    end
  end
end
