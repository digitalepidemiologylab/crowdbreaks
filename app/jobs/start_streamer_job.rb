class StartStreamerJob < ApplicationJob
  queue_as :default

  def perform
    api = AwsApi.new
    api.start_streamer
  end
end
