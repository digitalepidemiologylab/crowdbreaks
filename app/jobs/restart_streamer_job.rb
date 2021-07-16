class RestartStreamerJob < ApplicationJob
  queue_as :default

  def perform
    api = AwsApi.new
    api.restart_streamer
  end
end
