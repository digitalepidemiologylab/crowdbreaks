class UploadConfigJob < ApplicationJob
  queue_as :default

  def perform(config)
    api = AwsApi.new
    api.upload_config(config)
  end
end
