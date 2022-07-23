module Manage
  class ElasticsearchIndexesController < BaseController
    include Response
    authorize_resource class: false

    TIMESTAMP_INDEX = -21

    def index
      @api = AwsApi.new
      indices_stats = get_value_and_flash_now(@api.es_stats, default: {}).fetch('indices', nil)
      @health_status = get_value_and_flash_now(@api.es_health, default: {}).fetch('status', nil)
      @groups = {}
      indices_stats.each do |k, v|
        next if %w[. apm].map { |prefix| k.starts_with?(prefix) }.any?

        # @groups << { name: k, num_docs: v['total']['docs']['count'], size_bytes: v['total']['store']['size_in_bytes'] }

        group_name = k[0..TIMESTAMP_INDEX]
        index_stats = { num_indices: 1, num_docs: v['total']['docs']['count'], size_bytes: v['total']['store']['size_in_bytes'] }
        @groups[group_name] = if @groups.key?(group_name)
                                @groups[group_name].merge(index_stats) { |_k, v1, v2| v1 + v2 }
                              else
                                index_stats
                              end
        puts @groups
      end
      @groups = @groups.map { |k, v| { name: k }.merge(v) }
      @groups << {
        name: 'Total', num_indices: @groups.sum { |h| h[:num_indices] }, num_docs: @groups.sum { |h| h[:num_docs] },
        size_bytes: @groups.sum { |h| h[:size_bytes] }
      }
    end
  end
end
