module Manage
  class ElasticsearchIndexesController < BaseController
    authorize_resource class: false

    TIMESTAMP_INDEX = -21

    def index
      @api = AwsApi.new
      indices_stats = @api.es_stats['indices']
      @health_status = @api.es_health['status']
      @groups = {}
      indices_stats.each do |k, v|
        next if k.starts_with?('.')

        # @groups << { name: k, num_docs: v['total']['docs']['count'], size_bytes: v['total']['store']['size_in_bytes'] }

        group_name = k[0..TIMESTAMP_INDEX]
        index_stats = { num_indices: 1, num_docs: v['total']['docs']['count'], size_bytes: v['total']['store']['size_in_bytes'] }
        if @groups.key?(group_name)
          @groups[group_name] = @groups[group_name].merge(index_stats) { |_k, v1, v2| v1 + v2 }
        else
          @groups[group_name] = {}
        end
      end
      @groups = @groups.map { |k, v| { name: k }.merge(v) }
      puts @groups
    end
  end
end
