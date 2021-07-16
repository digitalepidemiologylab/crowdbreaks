class StopStreamerJob < ApplicationJob
  queue_as :default

  def perform
    api = AwsApi.new
    api.stop_streamer
  end
end