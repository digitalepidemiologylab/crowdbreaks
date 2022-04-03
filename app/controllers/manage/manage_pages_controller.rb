module Manage
  class ManagePagesController < BaseController
    include Response
    before_action :api_init

    def dashboard
      authorize! :view, :manage_dashboard
      # @status_streamer = get_value_and_flash_now(@api.status_streamer)
      @resource_groups = get_value_and_flash_now(@api.list_group_resources)
      @check_state = get_value_and_flash_now(@api.check_state)
      @status_delivery_streams = get_value_and_flash_now(@api.status_delivery_streams, default: [])
    end

    def streaming
      authorize! :configure, :streaming
      @stream_status = get_value_and_flash_now(@api.status_streaming)
      config = get_value_and_flash_now(@api.config, default: [])
      @up_to_date = Project.up_to_date?(config)
      @projects = Project.primary
    end

    def monitor_streams
      authorize! :configure, :streaming
      config = get_value_and_flash_now(@api.config, default: [])
      @current_streams = Project.primary.where(es_index_name: config.map { |stream| stream['es_index_name'] })
      @stream_status = get_value_and_flash_now(@api.status_streaming)
    end

    def user_activity
      authorize! :view, :user_activity
      @interval = 'day'
    end

    private

    def api_init
      @api = AwsApi.new
    end
  end
end
